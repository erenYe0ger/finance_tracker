from datetime import datetime, timezone

import jwt
from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from database import get_db
from dependencies.auth import CurrentUser, DbSession
from models import RefreshSession, User
from schemas.auth import Credentials, LogoutResponse, RefreshRequest, SafeUser, TokenPair
from security import create_access_token, create_refresh_token, hash_password
from security import hash_refresh_token, refresh_expiration, verify_password

router = APIRouter()
_DUMMY_PASSWORD_HASH = hash_password("dummy-login-password-not-for-use")


def issue_tokens(db: Session, user: User) -> TokenPair:
    refresh_token = create_refresh_token()
    access_token, expires_in = create_access_token(user.id)
    refresh_session = RefreshSession(
        user_id=user.id,
        token_hash=hash_refresh_token(refresh_token),
        expires_at=refresh_expiration(),
    )
    db.add(refresh_session)
    return TokenPair(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=expires_in,
    )


@router.post("/register", response_model=SafeUser, status_code=status.HTTP_201_CREATED)
def register(payload: Credentials, db: DbSession) -> SafeUser:
    user = User(email=payload.email, password_hash=hash_password(payload.password))
    db.add(user)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="An account with this email already exists") from None
    db.refresh(user)
    return user


@router.post("/login", response_model=TokenPair)
def login(payload: Credentials, db: DbSession) -> TokenPair:
    user = db.scalar(select(User).where(User.email == payload.email))
    stored_hash = user.password_hash if user is not None else _DUMMY_PASSWORD_HASH
    password_valid = verify_password(payload.password, stored_hash)
    if user is None or not password_valid:
        raise HTTPException(status_code=401, detail="Invalid email or password")

    tokens = issue_tokens(db, user)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=500, detail="Unable to create refresh session") from None
    return tokens


@router.post("/refresh", response_model=TokenPair)
def refresh(payload: RefreshRequest, db: DbSession) -> TokenPair:
    token_hash = hash_refresh_token(payload.refresh_token)
    session = db.scalar(
        select(RefreshSession)
        .where(RefreshSession.token_hash == token_hash)
        .with_for_update()
    )
    now = datetime.now(timezone.utc)
    if session is None:
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")

    if session.revoked_at is not None:
        if session.replaced_by_id is not None:
            # Reuse of a rotated credential may indicate theft; revoke the user's active sessions.
            db.query(RefreshSession).filter(
                RefreshSession.user_id == session.user_id,
                RefreshSession.revoked_at.is_(None),
            ).update({RefreshSession.revoked_at: now}, synchronize_session=False)
            db.commit()
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")
    expires_at = session.expires_at
    if expires_at.tzinfo is None:
        # Defensive handling for drivers that expose timezone-aware DB values as naive.
        expires_at = expires_at.replace(tzinfo=timezone.utc)
    if expires_at <= now:
        session.revoked_at = now
        db.commit()
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")

    user = db.get(User, session.user_id)
    if user is None:
        db.rollback()
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")

    session.revoked_at = now
    tokens = issue_tokens(db, user)
    try:
        db.flush()
        replacement = db.scalar(
            select(RefreshSession).where(
                RefreshSession.token_hash == hash_refresh_token(tokens.refresh_token)
            )
        )
        if replacement is None:
            db.rollback()
            raise HTTPException(status_code=401, detail="Invalid or expired refresh token")
        session.replaced_by_id = replacement.id
        db.commit()
    except HTTPException:
        raise
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token") from None
    return tokens


@router.post("/logout", response_model=LogoutResponse)
def logout(payload: RefreshRequest, db: DbSession) -> LogoutResponse:
    session = db.scalar(
        select(RefreshSession).where(
            RefreshSession.token_hash == hash_refresh_token(payload.refresh_token)
        )
    )
    if session is not None and session.revoked_at is None:
        session.revoked_at = datetime.now(timezone.utc)
        db.commit()
    return LogoutResponse(detail="Logged out")


@router.get("/me", response_model=SafeUser)
def me(user: CurrentUser) -> User:
    return user

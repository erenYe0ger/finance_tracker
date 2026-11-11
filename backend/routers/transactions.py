from datetime import date

from fastapi import APIRouter, HTTPException, Query, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from dependencies.auth import CurrentUser, DbSession
from models import Transaction
from schemas.transactions import (
    TransactionCategory,
    TransactionCreate,
    TransactionRead,
    TransactionType,
    TransactionUpdate,
    category_is_valid_for_type,
)

router = APIRouter()


def _not_found() -> HTTPException:
    return HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Transaction not found")


def _owned_transaction(db: Session, transaction_id: int, user_id: int) -> Transaction:
    transaction = db.scalar(
        select(Transaction).where(
            Transaction.id == transaction_id,
            Transaction.user_id == user_id,
        )
    )
    if transaction is None:
        raise _not_found()
    return transaction


@router.get("", response_model=list[TransactionRead])
def list_transactions(
    current_user: CurrentUser,
    db: DbSession,
    start_date: date | None = None,
    end_date: date | None = None,
    transaction_type: TransactionType | None = Query(default=None, alias="type"),
    category: TransactionCategory | None = None,
) -> list[Transaction]:
    if start_date is not None and end_date is not None and start_date > end_date:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="start_date must be on or before end_date",
        )
    if transaction_type is not None and category is not None:
        if not category_is_valid_for_type(transaction_type, category):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Category does not match transaction type",
            )

    statement = select(Transaction).where(Transaction.user_id == current_user.id)
    if start_date is not None:
        statement = statement.where(Transaction.transaction_date >= start_date)
    if end_date is not None:
        statement = statement.where(Transaction.transaction_date <= end_date)
    if transaction_type is not None:
        statement = statement.where(Transaction.transaction_type == transaction_type.value)
    if category is not None:
        statement = statement.where(Transaction.category == category.value)
    statement = statement.order_by(Transaction.transaction_date.desc(), Transaction.id.desc())
    return list(db.scalars(statement).all())


@router.post("", response_model=TransactionRead, status_code=status.HTTP_201_CREATED)
def create_transaction(
    payload: TransactionCreate,
    current_user: CurrentUser,
    db: DbSession,
) -> Transaction:
    transaction = Transaction(
        user_id=current_user.id,
        description=payload.description,
        amount_paise=payload.amount_paise,
        transaction_type=payload.type.value,
        category=payload.category.value,
        transaction_date=payload.transaction_date,
    )
    db.add(transaction)
    db.commit()
    db.refresh(transaction)
    return transaction


@router.get("/{transaction_id}", response_model=TransactionRead)
def get_transaction(
    transaction_id: int,
    current_user: CurrentUser,
    db: DbSession,
) -> Transaction:
    return _owned_transaction(db, transaction_id, current_user.id)


@router.patch("/{transaction_id}", response_model=TransactionRead)
def update_transaction(
    transaction_id: int,
    payload: TransactionUpdate,
    current_user: CurrentUser,
    db: DbSession,
) -> Transaction:
    transaction = _owned_transaction(db, transaction_id, current_user.id)
    update = payload.model_dump(exclude_unset=True)

    new_type = update.get("type", TransactionType(transaction.transaction_type))
    new_category = update.get("category", TransactionCategory(transaction.category))
    if new_type is None:
        new_type = TransactionType(transaction.transaction_type)
    if new_category is None:
        new_category = TransactionCategory(transaction.category)
    if not category_is_valid_for_type(new_type, new_category):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Category does not match transaction type",
        )

    for field in ("description", "amount_paise", "transaction_date"):
        if field in update:
            setattr(transaction, field, update[field])
    if "type" in update and update["type"] is not None:
        transaction.transaction_type = update["type"].value
    if "category" in update and update["category"] is not None:
        transaction.category = update["category"].value

    db.commit()
    db.refresh(transaction)
    return transaction


@router.delete("/{transaction_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_transaction(
    transaction_id: int,
    current_user: CurrentUser,
    db: DbSession,
) -> Response:
    transaction = _owned_transaction(db, transaction_id, current_user.id)
    db.delete(transaction)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)

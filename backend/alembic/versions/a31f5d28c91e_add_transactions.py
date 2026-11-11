"""add account-owned transactions

Revision ID: a31f5d28c91e
Revises: 9f2e1a7c4b60
Create Date: 2026-11-11

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "a31f5d28c91e"
down_revision: Union[str, Sequence[str], None] = "9f2e1a7c4b60"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "transactions",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("description", sa.String(length=120), nullable=False),
        sa.Column("amount_paise", sa.BigInteger(), nullable=False),
        sa.Column("transaction_type", sa.String(length=7), nullable=False),
        sa.Column("category", sa.String(length=24), nullable=False),
        sa.Column("transaction_date", sa.Date(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.CheckConstraint("amount_paise > 0", name="ck_transactions_amount_positive"),
        sa.CheckConstraint(
            "transaction_type IN ('income', 'expense')",
            name="ck_transactions_type_valid",
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_transactions_user_date",
        "transactions",
        ["user_id", "transaction_date", "id"],
    )


def downgrade() -> None:
    op.drop_index("ix_transactions_user_date", table_name="transactions")
    op.drop_table("transactions")

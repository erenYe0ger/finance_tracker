from datetime import date, datetime

from sqlalchemy import (
    BigInteger,
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    String,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column

from database import Base


class Transaction(Base):
    __tablename__ = "transactions"
    __table_args__ = (
        CheckConstraint("amount_paise > 0", name="ck_transactions_amount_positive"),
        CheckConstraint(
            "transaction_type IN ('income', 'expense')",
            name="ck_transactions_type_valid",
        ),
        Index("ix_transactions_user_date", "user_id", "transaction_date", "id"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    description: Mapped[str] = mapped_column(String(120), nullable=False)
    amount_paise: Mapped[int] = mapped_column(BigInteger, nullable=False)
    transaction_type: Mapped[str] = mapped_column(String(7), nullable=False)
    category: Mapped[str] = mapped_column(String(24), nullable=False)
    transaction_date: Mapped[date] = mapped_column(Date, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now()
    )

    @property
    def type(self) -> str:
        return self.transaction_type

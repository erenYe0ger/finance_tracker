from datetime import date
from enum import Enum

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator


class TransactionType(str, Enum):
    INCOME = "income"
    EXPENSE = "expense"


class TransactionCategory(str, Enum):
    FOOD = "Food"
    TRANSPORT = "Transport"
    BILLS = "Bills"
    SHOPPING = "Shopping"
    HEALTH = "Health"
    ENTERTAINMENT = "Entertainment"
    SALARY = "Salary"
    FREELANCE = "Freelance"
    INVESTMENT = "Investment"
    GIFT = "Gift"
    OTHER = "Other"


EXPENSE_CATEGORIES = {
    TransactionCategory.FOOD,
    TransactionCategory.TRANSPORT,
    TransactionCategory.BILLS,
    TransactionCategory.SHOPPING,
    TransactionCategory.HEALTH,
    TransactionCategory.ENTERTAINMENT,
    TransactionCategory.OTHER,
}
INCOME_CATEGORIES = {
    TransactionCategory.SALARY,
    TransactionCategory.FREELANCE,
    TransactionCategory.INVESTMENT,
    TransactionCategory.GIFT,
    TransactionCategory.OTHER,
}


def category_is_valid_for_type(
    transaction_type: TransactionType, category: TransactionCategory
) -> bool:
    allowed = INCOME_CATEGORIES if transaction_type is TransactionType.INCOME else EXPENSE_CATEGORIES
    return category in allowed


class TransactionFields(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    description: str = Field(min_length=1, max_length=120)
    amount_paise: int = Field(gt=0)
    type: TransactionType
    category: TransactionCategory
    transaction_date: date

    @field_validator("description")
    @classmethod
    def reject_blank_description(cls, value: str) -> str:
        if not value:
            raise ValueError("Description cannot be blank")
        return value

    @model_validator(mode="after")
    def validate_category_type(self):
        if not category_is_valid_for_type(self.type, self.category):
            raise ValueError("Category does not match transaction type")
        return self


class TransactionCreate(TransactionFields):
    pass


class TransactionUpdate(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    description: str | None = Field(default=None, min_length=1, max_length=120)
    amount_paise: int | None = Field(default=None, gt=0)
    type: TransactionType | None = None
    category: TransactionCategory | None = None
    transaction_date: date | None = None

    @field_validator("description")
    @classmethod
    def reject_blank_description(cls, value: str | None) -> str | None:
        if value is not None and not value:
            raise ValueError("Description cannot be blank")
        return value

    @model_validator(mode="after")
    def require_changes(self):
        if not self.model_fields_set:
            raise ValueError("At least one transaction field must be supplied")
        if any(getattr(self, field) is None for field in self.model_fields_set):
            raise ValueError("Transaction fields cannot be null")
        return self


class TransactionRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    description: str
    amount_paise: int
    type: TransactionType
    category: TransactionCategory
    transaction_date: date

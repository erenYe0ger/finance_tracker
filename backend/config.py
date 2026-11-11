from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    database_url: str
    jwt_secret_key: str
    jwt_access_token_expire_minutes: int = Field(default=15, ge=1, le=1440)
    jwt_refresh_token_expire_days: int = Field(default=30, ge=1, le=365)

    @field_validator("jwt_secret_key")
    @classmethod
    def validate_jwt_secret_key(cls, value: str) -> str:
        normalized = value.strip().lower()
        placeholders = (
            "replace_me",
            "change_me",
            "your_secret",
            "generate_a_random_secret",
        )
        if len(value) < 32 or any(placeholder in normalized for placeholder in placeholders):
            raise ValueError("JWT_SECRET_KEY must be a non-default secret of at least 32 characters")
        return value


settings = Settings()

from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException
from sqlalchemy import text

from database import engine, get_db
from config import settings
from routers.auth import router as auth_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: verify database connectivity
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
    except Exception:
        # Don't raise here - let the health endpoint report the status
        pass
    yield
    # Shutdown
    engine.dispose()


app = FastAPI(
    title="Finance Tracker API",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

app.include_router(auth_router, prefix="/api/v1/auth", tags=["authentication"])


@app.get("/api/v1/health", tags=["health"])
async def health_check():
    return {"status": "healthy", "service": "finance-tracker-api"}


@app.get("/api/v1/health/database", tags=["health"])
async def database_health_check():
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return {"status": "healthy", "database": "connected"}
    except Exception:
        raise HTTPException(status_code=503, detail="Database connection failed")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)

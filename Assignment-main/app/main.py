"""
Sample AI Microservice - FastAPI + PostgreSQL
Production-ready patterns: structured logging, /health & /ready probes,
Prometheus metrics, graceful DB pooling.
"""
import logging
import os
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel
from prometheus_fastapi_instrumentator import Instrumentator
from sqlalchemy import create_engine, Column, Integer, String, text
from sqlalchemy.orm import sessionmaker, declarative_base, Session

logging.basicConfig(
    level=logging.INFO,
    format='{"time":"%(asctime)s","level":"%(levelname)s","msg":"%(message)s"}',
)
logger = logging.getLogger("ai-microservice")

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres:postgres@localhost:5432/appdb",
)

engine = create_engine(DATABASE_URL, pool_pre_ping=True, pool_size=5, max_overflow=10)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


class Prediction(Base):
    __tablename__ = "predictions"
    id = Column(Integer, primary_key=True, index=True)
    input_text = Column(String, index=True)
    result = Column(String)


class PredictionIn(BaseModel):
    input_text: str


class PredictionOut(BaseModel):
    id: int
    input_text: str
    result: str


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@asynccontextmanager
async def lifespan(app: FastAPI):
    retries = 5
    for attempt in range(retries):
        try:
            Base.metadata.create_all(bind=engine)
            logger.info("Database connection established")
            break
        except Exception as e:
            logger.warning(f"DB not ready (attempt {attempt+1}/{retries}): {e}")
            time.sleep(3)
    yield
    logger.info("Shutting down application")


app = FastAPI(title="AI Microservice", version="1.0.0", lifespan=lifespan)

Instrumentator().instrument(app).expose(app, endpoint="/metrics")


@app.get("/", tags=["meta"])
def root():
    return {"service": "ai-microservice", "status": "running"}


@app.get("/health", tags=["probes"])
def health():
    """Liveness probe - process is alive, does not check dependencies."""
    return {"status": "healthy"}


@app.get("/ready", tags=["probes"])
def ready(db: Session = Depends(get_db)):
    """Readiness probe - checks DB connectivity before accepting traffic."""
    try:
        db.execute(text("SELECT 1"))
        return {"status": "ready"}
    except Exception as e:
        logger.error(f"Readiness check failed: {e}")
        raise HTTPException(status_code=503, detail="database not ready")


def fake_inference(text_in: str) -> str:
    return f"processed:{text_in[::-1]}"


@app.post("/predict", response_model=PredictionOut, tags=["inference"])
def predict(payload: PredictionIn, db: Session = Depends(get_db)):
    result = fake_inference(payload.input_text)
    record = Prediction(input_text=payload.input_text, result=result)
    db.add(record)
    db.commit()
    db.refresh(record)
    logger.info(f"prediction id={record.id}")
    return record


@app.get("/predict/{prediction_id}", response_model=PredictionOut, tags=["inference"])
def get_prediction(prediction_id: int, db: Session = Depends(get_db)):
    record = db.query(Prediction).filter(Prediction.id == prediction_id).first()
    if not record:
        raise HTTPException(status_code=404, detail="not found")
    return record

from fastapi import FastAPI

from app.database import engine
from app.database import Base
from app import models


Base.metadata.create_all(bind=engine)


app = FastAPI(
    title="Employee Management API",
    description="DevOps demonstration project",
    version="2.0.0"
)


@app.get("/")
def root():
    return {
        "message": "Welcome to Employee Management API"
    }


@app.get("/health")
def health_check():
    return {
        "status": "UP",
        "message": "Employee API is running"
    }
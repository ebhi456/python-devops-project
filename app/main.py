from fastapi import Depends, FastAPI
from sqlalchemy.orm import Session

from app import models
from app.database import Base, engine, get_db


Base.metadata.create_all(bind=engine)


app = FastAPI(
    title="Employee Management API",
    description="DevOps demonstration project",
    version="3.0.0"
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


@app.get("/employees")
def get_employees(
    db: Session = Depends(get_db)
):
    employees = db.query(models.Employee).all()

    return employees
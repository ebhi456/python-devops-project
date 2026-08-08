from fastapi import FastAPI, HTTPException
from pydantic import BaseModel


app = FastAPI(
    title="Employee Management API",
    description="DevOps demonstration project",
    version="1.0.0"
)


class Employee(BaseModel):
    name: str
    email: str
    department: str
    salary: float


employees = {
    1: {
        "id": 1,
        "name": "Rahul",
        "email": "rahul@example.com",
        "department": "DevOps",
        "salary": 75000
    },
    2: {
        "id": 2,
        "name": "Priya",
        "email": "priya@example.com",
        "department": "Cloud",
        "salary": 85000
    }
}


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
def get_employees():
    return list(employees.values())


@app.get("/employees/{employee_id}")
def get_employee(employee_id: int):

    if employee_id not in employees:
        raise HTTPException(
            status_code=404,
            detail="Employee not found"
        )

    return employees[employee_id]


@app.post("/employees")
def create_employee(employee: Employee):

    employee_id = max(employees.keys()) + 1

    new_employee = {
        "id": employee_id,
        **employee.model_dump()
    }

    employees[employee_id] = new_employee

    return new_employee


@app.put("/employees/{employee_id}")
def update_employee(
    employee_id: int,
    employee: Employee
):

    if employee_id not in employees:
        raise HTTPException(
            status_code=404,
            detail="Employee not found"
        )

    updated_employee = {
        "id": employee_id,
        **employee.model_dump()
    }

    employees[employee_id] = updated_employee

    return updated_employee


@app.delete("/employees/{employee_id}")
def delete_employee(employee_id: int):

    if employee_id not in employees:
        raise HTTPException(
            status_code=404,
            detail="Employee not found"
        )

    deleted_employee = employees.pop(employee_id)

    return {
        "message": "Employee deleted successfully",
        "employee": deleted_employee
    }
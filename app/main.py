from fastapi import FastAPI

app = FastAPI(
    title="Employee Management API",
    description="DevOps demonstration project",
    version="1.0.0"
)


@app.get("/health")
def health_check():
    return {
        "status": "UP",
        "message": "Employee API is running"
    }


@app.get("/")
def root():
    return {
        "message": "Welcome to Employee Management API"
    }
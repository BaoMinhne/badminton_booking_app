from fastapi import FastAPI

from app.routers import recommend, feedback, events, admin

app = FastAPI(title="Badminton Recommendation Service")


@app.get("/health")
async def health_check():
    return {"status": "ok"}


# Đăng ký routers
app.include_router(recommend.router)
app.include_router(feedback.router)
app.include_router(events.router)
app.include_router(admin.router)

import os
import uuid
from pathlib import Path

import httpx
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel, Field
from starlette.middleware.sessions import SessionMiddleware


# Load environment variables
load_dotenv(
    Path(__file__).with_name(".env"),
    interpolate=False
)

N8N_CHAT_URL = os.environ["N8N_CHAT_URL"]
N8N_USERNAME = os.environ["N8N_USERNAME"]
N8N_PASSWORD = os.environ["N8N_PASSWORD"]
SESSION_SECRET = os.environ["SESSION_SECRET"]


# Initialize FastAPI
app = FastAPI(
    title="Nova Estates AI API",
    description="AI-powered real estate assistant backend",
    version="1.0.0"
)


# Session management
app.add_middleware(
    SessionMiddleware,
    secret_key=SESSION_SECRET,
    same_site="strict",
    https_only=False,
    max_age=86400
)


# Data validation
class ChatRequest(BaseModel):
    message: str = Field(
        min_length=1,
        max_length=2000
    )


class ChatResponse(BaseModel):
    response: str


# Health check
@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "service": "Nova Estates AI"
    }


# Chat endpoint
@app.post("/api/chat", response_model=ChatResponse)
async def chat(data: ChatRequest, request: Request):

    message = data.message.strip()

    if not message:
        raise HTTPException(
            status_code=400,
            detail="Message cannot be empty"
        )

    if "session_id" not in request.session:
        request.session["session_id"] = str(uuid.uuid4())

    payload = {
        "action": "sendMessage",
        "sessionId": request.session["session_id"],
        "chatInput": message
    }

    try:
        async with httpx.AsyncClient(timeout=90.0) as client:
            result = await client.post(
                N8N_CHAT_URL,
                json=payload,
                auth=(N8N_USERNAME, N8N_PASSWORD)
            )

        result.raise_for_status()
        response_data = result.json()

        if isinstance(response_data, list):
            response_data = (
                response_data[0] if response_data else {}
            )

        if not isinstance(response_data, dict):
            raise HTTPException(
                status_code=502,
                detail="Invalid AI response"
            )

        output = response_data.get("output")

        if not isinstance(output, str) or not output.strip():
            raise HTTPException(
                status_code=502,
                detail="Empty or invalid AI response"
            )

        return ChatResponse(response=output)

    except httpx.TimeoutException:
        raise HTTPException(
            status_code=504,
            detail="AI service response timed out"
        )

    except (httpx.HTTPError, ValueError):
        raise HTTPException(
            status_code=502,
            detail="AI service temporarily unavailable"
        )


# Reset conversation
@app.post("/api/chat/reset")
async def reset_chat(request: Request):
    request.session.clear()

    return {
        "success": True,
        "message": "New conversation started"
    }


from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse

FRONTEND_DIR = Path(__file__).resolve().parent.parent / "frontend"

app.mount(
    "/static",
    StaticFiles(directory=FRONTEND_DIR),
    name="static"
)


@app.get("/", include_in_schema=False)
async def home():
    return FileResponse(FRONTEND_DIR / "index.html")








from collections import deque
from time import monotonic
from fastapi.responses import JSONResponse

RATE_LIMIT = 10
RATE_WINDOW = 60

request_history = deque()


@app.middleware("http")
async def rate_limit(request: Request, call_next):

    if request.method == "POST" and request.url.path in (
        "/api/chat",
        "/api/chat/reset"
    ):
        now = monotonic()

        while request_history and now - request_history[0] >= RATE_WINDOW:
            request_history.popleft()

        if len(request_history) >= RATE_LIMIT:
            return JSONResponse(
                status_code=429,
                content={
                    "detail": "Too many requests. Please try again later."
                },
                headers={"Retry-After": "60"}
            )

        request_history.append(now)

    return await call_next(request)



@app.middleware("http")
async def security_headers(request: Request, call_next):

    response = await call_next(request)

    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Referrer-Policy"] = "no-referrer"

    response.headers["Permissions-Policy"] = (
        "camera=(), microphone=(), geolocation=()"
    )

    if request.url.path == "/":
        response.headers["Content-Security-Policy"] = (
            "default-src 'self'; "
            "script-src 'self'; "
            "style-src 'self'; "
            "img-src 'self' data:; "
            "connect-src 'self'; "
            "frame-ancestors 'none'; "
            "object-src 'none'; "
            "base-uri 'self'; "
            "form-action 'self'"
        )

    if request.url.path.startswith("/api/"):
        response.headers["Cache-Control"] = "no-store"

    return response




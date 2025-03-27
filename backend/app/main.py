from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from api import router as api_router
from auth import router as auth_router
from database import engine, Base
import api


app = FastAPI()

# origins = [
#     "http://recipe.sigmoid.io", 
#     "http://localhost:3000",     
# ]

app.add_middleware(HTTPSRedirectMiddleware)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
@app.get("/health")
async def health_check():
    return {"status": "ok"}


@app.on_event("startup")
async def on_startup():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)



app.include_router(auth_router, prefix="/auth")
app.include_router(api_router, prefix="/api")

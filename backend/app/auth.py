# from dotenv import load_dotenv
# import os
# from sqlalchemy import select 
# from fastapi import APIRouter, HTTPException, Depends, Security
# from pydantic import BaseModel
# from sqlalchemy.ext.asyncio import AsyncSession
# from database import async_session
# from models import User
# from passlib.context import CryptContext
# from jose import JWTError, jwt
# from datetime import datetime, timedelta

# load_dotenv()
# SECRET_KEY = os.getenv("SECRET_KEY")
# ALGORITHM = "HS256"
# ACCESS_TOKEN_EXPIRE_MINUTES = 30

# pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# router = APIRouter()

# class UserCreate(BaseModel):
#     username: str
#     password: str

# class UserLogin(BaseModel):
#     username: str
#     password: str

# class Token(BaseModel):
#     access_token: str
#     token_type: str

# # Utility functions
# def verify_password(plain_password, hashed_password):
#     return pwd_context.verify(plain_password, hashed_password)

# def get_password_hash(password):
#     return pwd_context.hash(password)

# async def get_user_by_username(db: AsyncSession, username: str):
#     result = await db.execute(select(User).where(User.username == username))
#     return result.scalar_one_or_none()

# async def create_user(db: AsyncSession, user: UserCreate):
#     hashed_password = get_password_hash(user.password)
#     new_user = User(username=user.username, hashed_password=hashed_password)
#     db.add(new_user)
#     await db.commit()
#     await db.refresh(new_user)
#     return new_user

# def create_access_token(data: dict, expires_delta: timedelta = None):
#     to_encode = data.copy()
#     if expires_delta:
#         expire = datetime.utcnow() + expires_delta
#     else:
#         expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
#     to_encode.update({"exp": expire})
#     encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
#     return encoded_jwt

# @router.post("/signup", response_model=Token)
# async def signup(user: UserCreate):
#     async with async_session() as db:
#         existing_user = await get_user_by_username(db, user.username)
#         if existing_user:
#             raise HTTPException(status_code=400, detail="Username already registered")
#         new_user = await create_user(db, user)
#         access_token = create_access_token(data={"sub": new_user.username})
#         return {"access_token": access_token, "token_type": "bearer"}


# @router.post("/login", response_model=Token)
# async def login(user: UserLogin):
#     async with async_session() as db:
#         db_user = await get_user_by_username(db, user.username)
#         if not db_user:
#             raise HTTPException(status_code=400, detail="Incorrect username or password")
#         if not verify_password(user.password, db_user.hashed_password):
#             raise HTTPException(status_code=400, detail="Incorrect username or password")
#         access_token = create_access_token(data={"sub": db_user.username})
#         return {"access_token": access_token, "token_type": "bearer"}


# from fastapi.security import OAuth2PasswordBearer

# oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

# async def get_current_user(token: str = Depends(oauth2_scheme)):
#     credentials_exception = HTTPException(
#         status_code=401,
#         detail="Could not validate credentials",
#     )
#     try:
#         payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
#         username: str = payload.get("sub")
#         if username is None:
#             raise credentials_exception
#     except JWTError:
#         raise credentials_exception
    
#     async with async_session() as db:
#         user = await get_user_by_username(db, username)
#         if user is None:
#             raise credentials_exception
#         return user

from dotenv import load_dotenv
import os
from sqlalchemy import select 
from fastapi import APIRouter, HTTPException, Depends, Security
from pydantic import BaseModel, EmailStr
from sqlalchemy.ext.asyncio import AsyncSession
from database import async_session
from models import User, OTP
from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta
import random
import string
from fastapi.security import OAuth2PasswordBearer

load_dotenv()
SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

router = APIRouter(prefix="/auth", tags=["auth"])

# Models
class UserCreate(BaseModel):
    username: str
    email: str
    password: str

class UserLogin(BaseModel):
    username: str
    password: str

class EmailRequest(BaseModel):
    email: EmailStr

class OTPVerifyRequest(BaseModel):
    email: EmailStr
    otp: str

class Token(BaseModel):
    access_token: str
    token_type: str

# Utility functions
def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

async def get_user_by_username(db: AsyncSession, username: str):
    result = await db.execute(select(User).where(User.username == username))
    return result.scalar_one_or_none()

async def get_user_by_email(db: AsyncSession, email: str):
    result = await db.execute(select(User).where(User.email == email))
    return result.scalar_one_or_none()

async def create_user(db: AsyncSession, user: UserCreate):
    hashed_password = get_password_hash(user.password)
    new_user = User(
        username=user.username,
        email=user.email,
        hashed_password=hashed_password
    )
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)
    return new_user

def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

# OTP Functions
def generate_otp(length=6):
    return ''.join(random.choices(string.digits, k=length))

async def create_otp_record(db: AsyncSession, email: str):
    # Delete any existing OTPs for this email
    await db.execute(select(OTP).where(OTP.email == email).delete())
    await db.commit()
    
    # Create new OTP
    otp_code = generate_otp()
    otp_record = OTP(
        email=email,
        otp=otp_code,
        expires_at=datetime.utcnow() + timedelta(minutes=5)
    )
    db.add(otp_record)
    await db.commit()
    return otp_code

async def verify_otp_record(db: AsyncSession, email: str, otp: str):
    result = await db.execute(
        select(OTP).where(
            OTP.email == email,
            OTP.otp == otp,
            OTP.expires_at > datetime.utcnow()
        )
    )
    return result.scalar_one_or_none()

# Routes
@router.post("/send-otp")
async def send_otp(request: EmailRequest):
    async with async_session() as db:
        # Check if email already registered
        existing_user = await get_user_by_email(db, request.email)
        if existing_user:
            raise HTTPException(status_code=400, detail="Email already registered")
        
        # Create and store OTP
        otp_code = await create_otp_record(db, request.email)
        
        # In production, send OTP via email/SMS
        print(f"OTP for {request.email}: {otp_code}")  # Remove in production
        
        return {"message": "OTP sent successfully"}

@router.post("/verify-otp")
async def verify_otp(request: OTPVerifyRequest):
    async with async_session() as db:
        otp_record = await verify_otp_record(db, request.email, request.otp)
        if not otp_record:
            raise HTTPException(status_code=400, detail="Invalid OTP or OTP expired")
        
        # OTP is valid, mark email as verified (in session or return token)
        return {"message": "Email verified successfully", "email": request.email}

@router.post("/signup", response_model=Token)
async def signup(user: UserCreate):
    async with async_session() as db:
        # Check if username exists
        existing_user = await get_user_by_username(db, user.username)
        if existing_user:
            raise HTTPException(status_code=400, detail="Username already registered")
        
        # Check if email exists
        existing_email = await get_user_by_email(db, user.email)
        if existing_email:
            raise HTTPException(status_code=400, detail="Email already registered")
        
        # Create new user
        new_user = await create_user(db, user)
        access_token = create_access_token(data={"sub": new_user.username})
        return {"access_token": access_token, "token_type": "bearer"}

@router.post("/login", response_model=Token)
async def login(user: UserLogin):
    async with async_session() as db:
        db_user = await get_user_by_username(db, user.username)
        if not db_user:
            raise HTTPException(status_code=400, detail="Incorrect username or password")
        if not verify_password(user.password, db_user.hashed_password):
            raise HTTPException(status_code=400, detail="Incorrect username or password")
        access_token = create_access_token(data={"sub": db_user.username})
        return {"access_token": access_token, "token_type": "bearer"}

# Authentication dependency
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

async def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=401,
        detail="Could not validate credentials",
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    async with async_session() as db:
        user = await get_user_by_username(db, username)
        if user is None:
            raise credentials_exception
        return user

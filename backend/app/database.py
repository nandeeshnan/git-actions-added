# from dotenv import load_dotenv
# import os
# from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
# from sqlalchemy.orm import sessionmaker, declarative_base

# load_dotenv()
# DATABASE_URL = os.getenv("DATABASE_URL")
# engine = create_async_engine(DATABASE_URL, echo=True)
# async_session = sessionmaker(
#     engine, expire_on_commit=False, class_=AsyncSession
# )

# Base = declarative_base()


import boto3
import os
from dotenv import load_dotenv
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base

load_dotenv()

# Fetch the secret from AWS Secrets Manager
def get_secret(secret_name: str):
    region_name = "us-east-1"  # Replace with your AWS region

    # Create a Secrets Manager client
    client = boto3.client(service_name="secretsmanager", region_name=region_name)

    try:
        # Retrieve the secret value from Secrets Manager
        get_secret_value_response = client.get_secret_value(SecretId=secret_name)
        
        # Secrets are returned in either 'SecretString' or 'SecretBinary'
        if "SecretString" in get_secret_value_response:
            secret = get_secret_value_response["SecretString"]
            return secret
        else:
            raise ValueError("Secret not found or invalid format")
    except Exception as e:
        print(f"Error retrieving secret: {e}")
        raise e

# Fetch DATABASE_URL directly from AWS Secrets Manager
secret_name = "recipe-db-credentials"  # The name of the secret in Secrets Manager
secret = get_secret(secret_name)
secrets = eval(secret)  # If the secret is in JSON format
DATABASE_URL = secrets["DATABASE_URL"]  # Extract the DATABASE_URL from the secret

# Now you can use DATABASE_URL in your SQLAlchemy connection setup
engine = create_async_engine(DATABASE_URL, echo=True)

# Session and Base setup
async_session = sessionmaker(
    engine, expire_on_commit=False, class_=AsyncSession
)

Base = declarative_base()

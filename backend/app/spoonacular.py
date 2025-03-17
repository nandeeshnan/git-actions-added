import os
from dotenv import load_dotenv
import httpx
load_dotenv()
API_KEY = os.getenv("API_KEY")
# API_KEY = "c2927a6f1a064a8fa471e31d4d46269f"
BASE_URL = "https://api.spoonacular.com/recipes"

async def get_recipes_by_ingredients(ingredients: str, number: int = 20):
    params = {
        "ingredients": ingredients,
        "number": number,
        "apiKey": API_KEY
    }
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{BASE_URL}/findByIngredients", params=params)
        response.raise_for_status()
        return response.json()

async def get_recipe_details(recipe_id: int):
    params = {
        "includeNutrition": True,
        "apiKey": API_KEY
    }
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{BASE_URL}/{recipe_id}/information", params=params)
        response.raise_for_status()
        return response.json()

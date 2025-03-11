from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from pydantic import BaseModel
from auth import get_current_user
from database import async_session
from models import SavedRecipe
from spoonacular import get_recipes_by_ingredients, get_recipe_details

router = APIRouter()

class IngredientsRequest(BaseModel):
    ingredients: list[str]

@router.post("/recipes")
async def fetch_recipes(data: IngredientsRequest, current_user=Depends(get_current_user)):
    ingredients_str = ",".join(data.ingredients)
    try:
        recipes = await get_recipes_by_ingredients(ingredients_str)
        return recipes
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class SaveRecipeRequest(BaseModel):
    recipe_id: int
    title: str
    image: str
    details: str = None

@router.post("/save")
async def save_recipe(data: SaveRecipeRequest, current_user=Depends(get_current_user)):
    async with async_session() as db:
        new_saved = SavedRecipe(
            user_id=current_user.id,
            recipe_id=data.recipe_id,
            title=data.title,
            image=data.image,
            details=data.details
        )
        db.add(new_saved)
        await db.commit()
        await db.refresh(new_saved)
        return {"msg": "Recipe saved successfully", "saved_id": new_saved.id}

@router.get("/saved")
async def get_saved_recipes(current_user=Depends(get_current_user)):
    async with async_session() as db:
        result = await db.execute(select(SavedRecipe).where(SavedRecipe.user_id == current_user.id))
        saved = result.scalars().all()
        return saved

@router.delete("/saved/{saved_id}")
async def delete_saved_recipe(saved_id: int, current_user=Depends(get_current_user)):
    async with async_session() as db:
        result = await db.execute(select(SavedRecipe).where(SavedRecipe.id == saved_id, SavedRecipe.user_id == current_user.id))
        saved_recipe = result.scalar_one_or_none()
        if not saved_recipe:
            raise HTTPException(status_code=404, detail="Saved recipe not found")
        await db.delete(saved_recipe)
        await db.commit()
        return {"msg": "Deleted successfully"}

@router.get("/recipe/details")
async def recipe_details(recipe_id: int, current_user=Depends(get_current_user)):
    try:
        details = await get_recipe_details(recipe_id)
        return details
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

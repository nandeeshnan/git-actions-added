document.addEventListener('DOMContentLoaded', function() {
  const token = localStorage.getItem('token');
  const path = window.location.pathname.toLowerCase();

  // For protected pages (index.html, saved.html, details.html), if no token, redirect to login.
  if ((path.endsWith('index.html') || path.endsWith('saved.html') || path.endsWith('details.html')) && !token) {
    window.location.href = 'login.html';
    return;
  }
  // For public pages (login.html, signup.html), if token exists, redirect to index.
  if ((path.endsWith('login.html') || path.endsWith('signup.html')) && token) {
    window.location.href = 'index.html';
    return;
  }

  // Set profile name if available (username is stored at login)
  if (token) {
    const username = localStorage.getItem('username');
    if (username) {
      document.querySelectorAll('#profileName').forEach(el => el.innerText = username);
    }
  }

  // Attach event listeners based on the current page.
  if (path.endsWith('login.html')) {
    document.getElementById('loginForm').addEventListener('submit', loginHandler);
  } else if (path.endsWith('signup.html')) {
    document.getElementById('signupForm').addEventListener('submit', signupHandler);
  } else if (path.endsWith('index.html')) {
    document.getElementById('findRecipeBtn').addEventListener('click', fetchRecipesHandler);
    // If no previous search exists, fetch trending recipes.
    const storedResults = sessionStorage.getItem('lastSearchResults');
    if (storedResults) {
      displayRecipes(JSON.parse(storedResults));
    } 
    // else {
    //   fetchTrendingRecipes();
    // }
  } else if (path.endsWith('saved.html')) {
    fetchSavedRecipes();
  }
});

async function loginHandler(event) {
  event.preventDefault();
  const username = document.getElementById('username').value;
  const password = document.getElementById('password').value;

  try {
    const response = await fetch(window.BACKEND_URL + '/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password })
    });

    if (response.ok) {
      const data = await response.json();
      localStorage.setItem('token', data.access_token);
      localStorage.setItem('username', username);
      window.location.href = 'index.html';
    } else {
      alert('Login failed. Please check your credentials.');
    }
  } catch (error) {
    console.error('Login error:', error);
    alert('An error occurred during login.');
  }
}

async function signupHandler(event) {
  event.preventDefault();
  const username = document.getElementById('username').value;
  const password = document.getElementById('password').value;

  try {
    const response = await fetch(window.BACKEND_URL + '/auth/signup', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password })
    });

    if (response.ok) {
      alert('Signup successful! Please log in with your new credentials.');
      window.location.href = 'login.html';
    } else {
      alert('Signup failed. Please try again.');
    }
  } catch (error) {
    console.error('Signup error:', error);
    alert('An error occurred during signup.');
  }
}

async function fetchRecipesHandler() {
  const ingredientsInput = document.getElementById('ingredients').value;
  const ingredientsArray = ingredientsInput.split(',').map(item => item.trim()).filter(Boolean);

  if (ingredientsArray.length === 0) {
    alert('Please enter at least one ingredient.');
    return;
  }

  try {
    const response = await fetch(window.BACKEND_URL + '/api/recipes', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + localStorage.getItem('token')
      },
      body: JSON.stringify({ ingredients: ingredientsArray })
    });

    if (!response.ok) {
      throw new Error('Failed to fetch recipes');
    }

    const recipes = await response.json();
    // Store search results in sessionStorage so they persist when navigating back
    sessionStorage.setItem('lastSearchResults', JSON.stringify(recipes));
    displayRecipes(recipes);
  } catch (error) {
    console.error('Error fetching recipes:', error);
    alert(error.message);
  }
}


function displayRecipes(recipes) {
  const recipesDiv = document.getElementById('recipes');
  recipesDiv.innerHTML = '';
  recipes.forEach(recipe => {
    const card = document.createElement('div');
    card.classList.add('card', 'col-md-4', 'mb-4');
    card.innerHTML = `
      <img src="${recipe.image}" class="card-img-top" alt="${recipe.title}">
      <div class="card-body">
        <h5 class="card-title">${recipe.title}</h5>
        <div class="btn-group">
          <button class="btn btn-sm btn-primary" onclick='viewDetails(${recipe.id})'>View Details</button>
          <button class="btn btn-sm btn-success" onclick='saveRecipe(${JSON.stringify(recipe)})'>Save Recipe</button>
        </div>
      </div>
    `;
    recipesDiv.appendChild(card);
  });
}

function viewDetails(recipeId) {
  // Redirect to details.html with recipe id as query parameter.
  window.location.href = `details.html?id=${recipeId}`;
}

async function saveRecipe(recipe) {
  try {
    const response = await fetch(window.BACKEND_URL + '/api/save', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + localStorage.getItem('token')
      },
      body: JSON.stringify({
        recipe_id: recipe.id,
        title: recipe.title,
        image: recipe.image,
        details: JSON.stringify({
          used: recipe.usedIngredientCount,
          missed: recipe.missedIngredientCount
        })
      })
    });

    if (response.ok) {
      alert("Recipe saved successfully!");
    } else {
      alert("Failed to save recipe.");
    }
  } catch (error) {
    console.error('Error saving recipe:', error);
    alert(error.message);
  }
}

async function fetchSavedRecipes() {
  try {
    const response = await fetch(window.BACKEND_URL + '/api/saved', {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + localStorage.getItem('token')
      }
    });
    if (!response.ok) {
      throw new Error('Failed to fetch saved recipes');
    }
    const savedRecipes = await response.json();
    displaySaved(savedRecipes);
  } catch (error) {
    console.error('Error fetching saved recipes:', error);
    alert(error.message);
  }
}

function displaySaved(recipes) {
  const container = document.getElementById('savedRecipes');
  container.innerHTML = '';
  recipes.forEach(recipe => {
    const card = document.createElement('div');
    card.classList.add('card', 'col-md-4', 'mb-4');
    card.innerHTML = `
      <img src="${recipe.image}" class="card-img-top" alt="${recipe.title}">
      <div class="card-body">
        <h5 class="card-title">${recipe.title}</h5>
        <div class="btn-group">
          <button class="btn btn-sm btn-primary" onclick='viewDetails(${recipe.recipe_id})'>View Details</button>
          <button class="btn btn-sm btn-danger" onclick='deleteSaved(${recipe.id})'>Delete</button>
        </div>
      </div>
    `;
    container.appendChild(card);
  });
}

async function deleteSaved(savedId) {
  try {
    const response = await fetch(`${window.BACKEND_URL}/api/saved/${savedId}`, {
      method: 'DELETE',
      headers: { 'Authorization': 'Bearer ' + localStorage.getItem('token') }
    });
    if (response.ok) {
      alert("Deleted successfully!");
      fetchSavedRecipes();
    } else {
      alert("Failed to delete saved recipe.");
    }
  } catch (error) {
    console.error('Error deleting saved recipe:', error);
    alert(error.message);
  }
}

function logoutHandler() {
  localStorage.removeItem('token');
  localStorage.removeItem('username');
  window.location.href = 'login.html';
}
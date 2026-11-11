class Api::V1::RecipesController < ApplicationController
  before_action :set_recipe, only: %i[show update destroy]

  def index
    recipes = Recipe.includes(recipe_ingredients: :ingredient).order(:name)
    render json: recipes.map { |recipe| RecipeSerializer.summary(recipe) }
  end

  def show
    render json: RecipeSerializer.detail(@recipe)
  end

  def create
    recipe = Recipe.new(recipe_params)

    if recipe.save
      render json: RecipeSerializer.detail(recipe), status: :created
    else
      render_errors recipe.errors
    end
  end

  # Nested attributes: lines with an id are updated, lines with id + _destroy are removed,
  # lines without an id are created. All in one transaction, so a bad line saves nothing.
  def update
    if @recipe.update(recipe_params)
      render json: RecipeSerializer.detail(@recipe)
    else
      render_errors @recipe.errors
    end
  end

  def destroy
    @recipe.destroy!
    head :no_content
  end

  # Builds the recipe in memory and returns its costs. Saves nothing.
  # Name errors are dropped: previewing an existing recipe would otherwise fail
  # the uniqueness check. Everything else (servings, lines) must be valid to cost it.
  def preview
    recipe = Recipe.new(recipe_params)
    recipe.validate
    recipe.errors.delete(:name)

    if recipe.errors.empty?
      render json: RecipeSerializer.detail(recipe)
    else
      render_errors recipe.errors
    end
  end

  private

  def set_recipe
    @recipe = Recipe.includes(recipe_ingredients: :ingredient).find(params[:id])
  end

  def recipe_params
    params.expect(
      recipe: [
        :name, :servings, :menu_price_cents, :notes,
        recipe_ingredients_attributes: [ [ :id, :ingredient_id, :quantity, :unit, :_destroy ] ]
      ]
    )
  end
end

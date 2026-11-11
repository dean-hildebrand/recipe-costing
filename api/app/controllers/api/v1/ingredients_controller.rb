class Api::V1::IngredientsController < ApplicationController
  FIELDS = %i[id name purchase_quantity purchase_unit purchase_price_cents yield_percent].freeze

  before_action :set_ingredient, only: %i[show update destroy]

  def index
    render json: Ingredient.order(:name).map { |ingredient| serialize(ingredient) }
  end

  def show
    render json: serialize(@ingredient)
  end

  def create
    ingredient = Ingredient.new(ingredient_params)

    if ingredient.save
      render json: serialize(ingredient), status: :created
    else
      render_errors ingredient.errors
    end
  end

  def update
    if @ingredient.update(ingredient_params)
      render json: serialize(@ingredient)
    else
      render_errors @ingredient.errors
    end
  end

  # restrict_with_error adds an error to :base when a recipe uses this ingredient,
  # so destroy returns false instead of hitting the ON DELETE RESTRICT foreign key.
  def destroy
    if @ingredient.destroy
      head :no_content
    else
      render_errors @ingredient.errors
    end
  end

  private

  def set_ingredient
    @ingredient = Ingredient.find(params[:id])
  end

  def ingredient_params
    params.expect(ingredient: %i[name purchase_quantity purchase_unit purchase_price_cents yield_percent])
  end

  def serialize(ingredient)
    ingredient.as_json(only: FIELDS)
  end
end

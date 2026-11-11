class Api::V1::UnitsController < ApplicationController
  def index
    units = Units::DIMENSIONS
    render json: units
  end
end

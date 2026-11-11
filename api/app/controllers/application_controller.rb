class ApplicationController < ActionController::API
  # Every error response uses one shape: { "errors": { "field": ["message"] } }
  rescue_from ActiveRecord::RecordNotFound do |e|
    render_errors({ base: [ "#{e.model || 'Record'} not found" ] }, status: :not_found)
  end

  rescue_from ActionController::ParameterMissing do |e|
    render_errors({ base: [ e.message ] }, status: :bad_request)
  end

  private

  def render_errors(errors, status: :unprocessable_content)
    errors = errors.to_hash if errors.is_a?(ActiveModel::Errors)
    render json: { errors: errors }, status: status
  end
end

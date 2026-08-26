class ShortLinksController < ApplicationController
  rescue_from EncoderError, with: :render_encoder_error
  rescue_from CodeCollisionError, with: :render_code_collision_error

  def create
    short_link = ShortLinkEncoder.new(url).call

    render json: { short_url: "#{request.base_url}/#{short_link.code}" }, status: :ok
  end

  def show
    short_link = ShortLink.find_by!(code: params[:code])

    render json: { url: short_link.original_link }, status: :ok
  end

  private

  def url
    @url ||= params.require(:url)
  end

  def render_encoder_error(exception)
    render_error(exception, status: :unprocessable_entity)
  end

  def render_code_collision_error(exception)
    render_error(exception, status: :service_unavailable)
  end

  def render_error(exception, status:)
    render json: {
      error: exception.error_code,
      error_message: exception.message
    }, status: status
  end
end

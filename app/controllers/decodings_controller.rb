class DecodingsController < ApplicationController
  def create
    render json: { url: "https://example.com/very/long/url" }, status: :ok
  end
end

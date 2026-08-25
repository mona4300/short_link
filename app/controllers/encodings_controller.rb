class EncodingsController < ApplicationController
  def create
    render json: { short_url: "https://short.est/abc123" }, status: :ok
  end
end

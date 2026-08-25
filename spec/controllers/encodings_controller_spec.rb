require "rails_helper"

RSpec.describe EncodingsController, type: :controller do
  describe "POST #create" do
    it "returns a dummy short url" do
      post :create

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        "short_url" => "https://short.est/abc123"
      )
    end
  end
end

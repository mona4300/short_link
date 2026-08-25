require "rails_helper"

RSpec.describe DecodingsController, type: :controller do
  describe "POST #create" do
    it "returns a dummy original url" do
      post :create

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        "url" => "https://example.com/very/long/url"
      )
    end
  end
end

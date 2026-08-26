require "rails_helper"

RSpec.describe ShortLinksController, type: :controller do
  describe "POST #create" do
    let(:url) { "https://example.com/articles/how-to-build-a-short-link-service" }

    it "encodes the url and returns a short url" do
      post :create, params: { url: url }, as: :json

      expect(response).to have_http_status(:ok)

      short_url = response.parsed_body["short_url"]
      expect(short_url).to match(%r{\A#{Regexp.escape(request.base_url)}/[A-Za-z0-9]{#{ShortLink::CODE_LENGTH}}\z})

      code = short_url.split("/").last
      expect(ShortLink.find_by!(code: code).original_link).to eq(url)
    end

    it "returns error and error_message when the url is invalid" do
      post :create, params: { url: "http://localhost" }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to eq(
        "error" => "localhost",
        "error_message" => "Localhost URLs are not allowed"
      )
    end

    it "returns error and error_message when code generation collides" do
      encoder = instance_double(ShortLinkEncoder)
      allow(ShortLinkEncoder).to receive(:new).with(url).and_return(encoder)
      allow(encoder).to receive(:call).and_raise(CodeCollisionError)

      post :create, params: { url: url }, as: :json

      expect(response).to have_http_status(:service_unavailable)
      expect(response.parsed_body).to eq(
        "error" => "code_collision",
        "error_message" => "Unable to generate a unique short link. Please try again."
      )
    end
  end

  describe "GET #show" do
    let!(:short_link) { create(:short_link) }

    it "returns the original url for the given code" do
      get :show, params: { code: short_link.code }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("url" => short_link.original_link)
    end
  end
end

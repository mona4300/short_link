require "rails_helper"

RSpec.describe ShortLinkEncoder do
  describe "#call" do
    it "creates a short link for a valid url" do
      url = "https://example.com/articles/how-to-build-a-short-link-service"
      encoder = described_class.new(url)

      short_link = encoder.call

      expect(short_link).to be_persisted
      expect(short_link.original_link).to eq(url)
      expect(encoder.short_link).to eq(short_link)
    end

    it "raises an encoder error when the validator rejects the url" do
      encoder = described_class.new("http://localhost")

      expect { encoder.call }.to raise_error(EncoderError) do |error|
        expect(error.error_code).to eq(:localhost)
        expect(error.message).to eq("Localhost URLs are not allowed")
      end
      expect(encoder.short_link).to be_nil
    end
  end

  describe "#valid?" do
    it "delegates to the url validator" do
      encoder = described_class.new("https://example.com")

      expect(encoder.valid?).to be(true)
    end
  end
end

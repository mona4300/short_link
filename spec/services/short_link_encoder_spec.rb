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

    it "raises an encoder error when the model rejects the record" do
      url = "https://example.com/articles/how-to-build-a-short-link-service"
      encoder = described_class.new(url)

      allow(encoder).to receive(:generate_code).and_return("short")

      expect { encoder.call }.to raise_error(EncoderError) do |error|
        expect(error.error_code).to eq(:invalid)
        expect(error.message).to eq("Code is the wrong length (should be 10 characters)")
      end
      expect(encoder.short_link).to be_nil
    end

    it "retries on code collisions and succeeds" do
      url = "https://example.com/articles/how-to-build-a-short-link-service"
      collision_code = "abc1234567"
      success_code = "xyz9876543"
      create(:short_link, code: collision_code)
      encoder = described_class.new(url)

      allow(encoder).to receive(:generate_code).and_return(collision_code, success_code)
      allow(ShortLink).to receive(:create!).and_call_original

      short_link = encoder.call

      expect(short_link).to be_persisted
      expect(short_link.code).to eq(success_code)
      expect(ShortLink).to have_received(:create!).twice
    end

    it "raises a code collision error after exhausting retries" do
      url = "https://example.com/articles/how-to-build-a-short-link-service"
      collision_code = "abc1234567"
      create(:short_link, code: collision_code)
      encoder = described_class.new(url)

      allow(encoder).to receive(:generate_code).and_return(collision_code)
      allow(ShortLink).to receive(:create!).and_call_original

      expect { encoder.call }.to raise_error(CodeCollisionError)
      expect(ShortLink).to have_received(:create!).exactly(described_class::MAX_ATTEMPTS).times
    end
  end

  describe "#valid?" do
    it "delegates to the url validator" do
      encoder = described_class.new("https://example.com")

      expect(encoder.valid?).to be(true)
    end
  end
end

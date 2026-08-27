require "rails_helper"

RSpec.describe UrlValidator do
  describe "#valid?" do
    it "returns true for a public https url" do
      validator = described_class.new("https://example.com/path")

      expect(validator.valid?).to be(true)
      expect(validator.error).to be_nil
      expect(validator.error_message).to be_nil
    end

    it "rejects a blank url" do
      validator = described_class.new("")

      expect(validator.valid?).to be(false)
      expect(validator.error).to eq(:blank)
      expect(validator.error_message).to eq("URL is required")
    end

    it "rejects an invalid url format" do
      validator = described_class.new("not-a-url")

      expect(validator.valid?).to be(false)
      expect(validator.error).to eq(:invalid)
      expect(validator.error_message).to eq("URL is invalid")
    end

    it "rejects localhost" do
      validator = described_class.new("http://localhost/path")

      expect(validator.valid?).to be(false)
      expect(validator.error).to eq(:localhost)
      expect(validator.error_message).to eq("Localhost URLs are not allowed")
    end

    it "rejects internal hostnames" do
      validator = described_class.new("http://internal")

      expect(validator.valid?).to be(false)
      expect(validator.error).to eq(:internal_host)
      expect(validator.error_message).to eq("Internal hostnames are not allowed")
    end

    it "rejects urls with embedded credentials" do
      validator = described_class.new("https://user:pass@example.com/path")

      expect(validator.valid?).to be(false)
      expect(validator.error).to eq(:userinfo)
      expect(validator.error_message).to eq("URLs with embedded credentials are not allowed")
    end

    it "rejects a non-string url without raising" do
      validator = described_class.new([ "https://example.com", "https://other.com" ])

      expect(validator.valid?).to be(false)
      expect(validator.error).to eq(:invalid)
    end

    it "rejects hosts that resolve to a private address" do
      stub_dns(addresses: [ IPAddr.new("10.0.0.5") ])
      validator = described_class.new("https://private.example.com/path")

      expect(validator.valid?).to be(false)
      expect(validator.error).to eq(:private_address)
      expect(validator.error_message).to eq("Private or reserved network addresses are not allowed")
    end

    it "rejects hosts that cannot be resolved" do
      stub_dns_failure
      validator = described_class.new("https://missing.example.com/path")

      expect(validator.valid?).to be(false)
      expect(validator.error).to eq(:unresolvable_host)
      expect(validator.error_message).to eq("URL host could not be resolved")
    end

    it "normalizes the host and drops a default port" do
      validator = described_class.new("HTTPS://Example.COM.:443/Path?q=1")

      expect(validator.valid?).to be(true)
      expect(validator.normalized_url).to eq("https://example.com/Path?q=1")
    end

    it "rejects ip address urls" do
      validator = described_class.new("http://8.8.8.8/path")

      expect(validator.valid?).to be(false)
      expect(validator.error).to eq(:ip_address)
      expect(validator.error_message).to eq("IP address URLs are not allowed")
    end

    it "rejects private ip urls as ip addresses" do
      validator = described_class.new("http://192.168.1.10/admin")

      expect(validator.valid?).to be(false)
      expect(validator.error).to eq(:ip_address)
      expect(validator.error_message).to eq("IP address URLs are not allowed")
    end

    it "rejects custom ports" do
      validator = described_class.new("https://example.com:8443/path")

      expect(validator.valid?).to be(false)
      expect(validator.error).to eq(:custom_port)
      expect(validator.error_message).to eq("Custom ports are not allowed")
    end

    it "rejects urls that exceed the maximum length" do
      url = "https://example.com/#{'a' * ShortLink::MAX_ORIGINAL_LINK_LENGTH}"
      validator = described_class.new(url)

      expect(validator.valid?).to be(false)
      expect(validator.error).to eq(:too_long)
      expect(validator.error_message).to eq("URL is too long")
    end

    it "rejects unsupported schemes" do
      validator = described_class.new("ftp://example.com/path")

      expect(validator.valid?).to be(false)
      expect(validator.error).to eq(:invalid_scheme)
      expect(validator.error_message).to eq("URL scheme must be http or https")
    end

    it "rejects internationalized domain names" do
      validator = described_class.new("https://xn--xample-2of.com/path")

      expect(validator.valid?).to be(false)
      expect(validator.error).to eq(:idn_host)
      expect(validator.error_message).to eq("Internationalized domain names are not allowed")
    end

    it "rejects invalid hostnames" do
      validator = described_class.new("https://myserver/path")

      expect(validator.valid?).to be(false)
      expect(validator.error).to eq(:invalid_host)
      expect(validator.error_message).to eq("URL host is invalid")
    end

    it "rejects obfuscated ip address urls" do
      validator = described_class.new("http://2130706433/path")

      expect(validator.valid?).to be(false)
      expect(validator.error).to eq(:ip_address)
    end

    it "encodes @ characters in path, query, and fragment" do
      validator = described_class.new("https://example.com/a@b?c@d#e@f")

      expect(validator.valid?).to be(true)
      expect(validator.normalized_url).to eq("https://example.com/a%40b?c%40d#e%40f")
    end
  end
end

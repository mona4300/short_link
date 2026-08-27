require "rails_helper"

RSpec.describe UrlValidator::IpAddressParser do
  describe ".call" do
    it "parses a dotted-decimal IPv4 address" do
      expect(described_class.call("8.8.8.8")).to eq(IPAddr.new("8.8.8.8"))
    end

    it "parses a decimal integer IPv4 address" do
      expect(described_class.call("2130706433")).to eq(IPAddr.new("127.0.0.1"))
    end

    it "parses abbreviated dotted IPv4 forms" do
      expect(described_class.call("127.1")).to eq(IPAddr.new("127.0.0.1"))
      expect(described_class.call("127.0.1")).to eq(IPAddr.new("127.0.0.1"))
    end

    it "parses hex and octal IPv4 parts" do
      expect(described_class.call("0x7f.0.0.1")).to eq(IPAddr.new("127.0.0.1"))
      expect(described_class.call("0177.0.0.1")).to eq(IPAddr.new("127.0.0.1"))
    end

    it "parses bracketed and bare IPv6 addresses" do
      expect(described_class.call("[::1]")).to eq(IPAddr.new("::1"))
      expect(described_class.call("::1")).to eq(IPAddr.new("::1"))
    end

    it "parses IPv4-mapped IPv6 addresses" do
      expect(described_class.call("::ffff:127.0.0.1")).to eq(IPAddr.new("::ffff:127.0.0.1"))
    end

    it "returns nil for hostnames" do
      expect(described_class.call("example.com")).to be_nil
    end

    it "returns nil for invalid numeric forms" do
      expect(described_class.call("08.0.0.1")).to be_nil
      expect(described_class.call("1e2.0.0.1")).to be_nil
      expect(described_class.call("127.0.0.1.")).to be_nil
      expect(described_class.call("256.0.0.1")).to be_nil
    end

    it "returns nil for invalid IPv6" do
      expect(described_class.call("::gggg")).to be_nil
    end
  end
end

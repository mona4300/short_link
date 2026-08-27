require "rails_helper"

RSpec.describe UrlValidator::AddressPolicy do
  describe ".call" do
    it "allows public IPv4 addresses" do
      expect(described_class.call(IPAddr.new("8.8.8.8"))).to be(true)
    end

    it "allows public IPv6 addresses" do
      expect(described_class.call(IPAddr.new("2001:4860:4860::8888"))).to be(true)
    end

    it "blocks private and loopback IPv4 ranges" do
      %w[
        10.0.0.5
        127.0.0.1
        169.254.169.254
        172.16.0.1
        192.168.1.10
        100.64.0.1
        192.0.2.1
        224.0.0.1
      ].each do |address|
        expect(described_class.call(IPAddr.new(address))).to be(false), "expected #{address} to be blocked"
      end
    end

    it "blocks private and loopback IPv6 ranges" do
      %w[
        ::1
        fc00::1
        fe80::1
        ff00::1
        2001:db8::1
        64:ff9b::1
      ].each do |address|
        expect(described_class.call(IPAddr.new(address))).to be(false), "expected #{address} to be blocked"
      end
    end

    it "blocks IPv4-mapped IPv6 loopback addresses" do
      expect(described_class.call(IPAddr.new("::ffff:127.0.0.1"))).to be(false)
    end
  end
end

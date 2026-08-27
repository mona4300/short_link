require "rails_helper"

RSpec.describe UrlValidator::DnsResolver do
  describe "#resolve" do
    let(:dns) { instance_double(Resolv::DNS) }

    before do
      allow(Resolv::DNS).to receive(:new).and_return(dns)
      allow(dns).to receive(:timeouts=)
      allow(dns).to receive(:close)
    end

    it "returns IPv4 and IPv6 addresses from DNS" do
      allow(dns).to receive(:getresources)
        .with("example.com", Resolv::DNS::Resource::IN::A)
        .and_return([ instance_double(Resolv::DNS::Resource::IN::A, address: "93.184.216.34") ])
      allow(dns).to receive(:getresources)
        .with("example.com", Resolv::DNS::Resource::IN::AAAA)
        .and_return([ instance_double(Resolv::DNS::Resource::IN::AAAA, address: "2606:2800:220:1:248:1893:25c8:1946") ])

      addresses = described_class.new("example.com").resolve

      expect(addresses).to eq([
        IPAddr.new("93.184.216.34"),
        IPAddr.new("2606:2800:220:1:248:1893:25c8:1946")
      ])
      expect(dns).to have_received(:timeouts=).with(described_class::TIMEOUT_SECONDS)
      expect(dns).to have_received(:close)
    end

    it "raises when DNS returns no addresses" do
      allow(dns).to receive(:getresources).and_return([])

      expect {
        described_class.new("empty.example.com").resolve
      }.to raise_error(described_class::Error, /no addresses/)
      expect(dns).to have_received(:close)
    end

    it "raises when DNS lookup fails" do
      allow(dns).to receive(:getresources).and_raise(Resolv::ResolvError, "NXDOMAIN")

      expect {
        described_class.new("missing.example.com").resolve
      }.to raise_error(described_class::Error, /DNS lookup failed/)
      expect(dns).to have_received(:close)
    end

    it "raises when DNS lookup times out" do
      allow(dns).to receive(:getresources).and_raise(Resolv::ResolvTimeout, "timed out")

      expect {
        described_class.new("slow.example.com").resolve
      }.to raise_error(described_class::Error, /DNS lookup failed/)
      expect(dns).to have_received(:close)
    end
  end

  describe ".resolve" do
    it "delegates to an instance" do
      # Bypass the suite-wide DnsResolver stub so this exercises the real class method.
      allow(described_class).to receive(:resolve).and_call_original

      resolver = instance_double(described_class, resolve: [ IPAddr.new("8.8.8.8") ])
      allow(described_class).to receive(:new).with("example.com").and_return(resolver)

      expect(described_class.resolve("example.com")).to eq([ IPAddr.new("8.8.8.8") ])
    end
  end
end

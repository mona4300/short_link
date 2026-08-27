# UrlValidator resolves hosts via DnsResolver, which
# would otherwise hit real DNS (slow, flaky, and environment-dependent).
module DnsResolutionHelper
  PUBLIC_ADDRESS = IPAddr.new("93.184.216.34").freeze # example.com (documentation-friendly)

  def stub_dns(addresses: [ PUBLIC_ADDRESS ])
    allow(UrlValidator::DnsResolver).to receive(:resolve).and_return(addresses)
  end

  def stub_dns_failure(message: "DNS lookup failed")
    error = UrlValidator::DnsResolver::Error.new(message)
    allow(UrlValidator::DnsResolver).to receive(:resolve).and_raise(error)
  end
end

RSpec.configure do |config|
  config.include DnsResolutionHelper

  config.before do
    stub_dns
  end
end

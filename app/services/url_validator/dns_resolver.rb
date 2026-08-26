require "ipaddr"
require "resolv"

class UrlValidator
  # Looks up the real IP address(es) behind a hostname.
  #
  # Why this exists:
  #   A hostname like "localtest.me" looks harmless as text, but DNS can say
  #   it points at 127.0.0.1 (your own machine) or a private office IP.
  #   Without resolving the name to IP(s), AddressPolicy never gets a chance
  #   to block those destinations.
  #
  #   We ask for both IPv4 (A records) and IPv6 (AAAA records).
  #   CNAME chains (name → another name → IP) are
  #   followed by Resolv automatically — that is *not* an HTTP redirect.
  #
  # Fail closed:
  #   If the lookup fails, times out, or returns nothing, we raise Error.
  #   Callers should treat that as "reject the URL" — never "assume it's fine".
  #
  # Returns:
  #   Array of IPAddr  → at least one address from DNS
  # Raises:
  #   DnsResolver::Error → lookup failed / timed out / empty answer
  class DnsResolver
    class Error < StandardError; end

    # How long (seconds) we wait for DNS before giving up.
    # Short on purpose: a stuck lookup must not hang a create-link request.
    TIMEOUT_SECONDS = 2

    def self.resolve(host)
      new(host).resolve
    end

    def initialize(host)
      @host = host.to_s
    end

    def resolve
      # Step 1: open a DNS client with a hard time budget.
      #   timeouts = 2 → "answer within 2 seconds or we stop waiting".
      dns = Resolv::DNS.new
      dns.timeouts = TIMEOUT_SECONDS

      begin
        # Step 2: ask for IPv4 (A) and IPv6 (AAAA) answers for this name.
        #   A    → classic addresses like 140.82.121.4
        #   AAAA → newer IPv6 addresses like 2606:4700:...
        #   Either family alone is enough; we collect both when present.
        ipv4 = dns.getresources(@host, Resolv::DNS::Resource::IN::A)
                  .map { |record| IPAddr.new(record.address.to_s) }
        ipv6 = dns.getresources(@host, Resolv::DNS::Resource::IN::AAAA)
                  .map { |record| IPAddr.new(record.address.to_s) }
        addresses = ipv4 + ipv6
      rescue Resolv::ResolvError, Resolv::ResolvTimeout => e
        # ResolvError   → NXDOMAIN, SERVFAIL, malformed answer, etc.
        # ResolvTimeout → no reply before TIMEOUT_SECONDS.
        raise Error, "DNS lookup failed for #{@host}: #{e.message}"
      ensure
        # Always close the client so we do not leak sockets / file descriptors.
        dns.close
      end

      # Step 3: empty answer = "we could not prove a public destination".
      #   Fail closed: do not treat "no IPs" as success.
      raise Error, "DNS returned no addresses for #{@host}" if addresses.empty?

      addresses
    end
  end
end

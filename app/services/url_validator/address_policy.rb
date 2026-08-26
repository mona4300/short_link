require "ipaddr"

class UrlValidator
  # Decides whether an IP address is safe to treat as "public internet".
  #
  # Why this exists:
  #   A short-link service must not redirect users (or the server itself) to
  #   addresses that only make sense inside a private network — e.g. your
  #   home router (192.168.x.x), the machine itself (127.0.0.1), or cloud
  #   metadata endpoints (169.254.169.254). Those are not "reachable public"
  #   destinations; allowing them is a classic SSRF / open-redirect risk.
  #
  # Input:
  #   An IPAddr
  #
  # Returns:
  #   true  → address looks like a normal public internet IP
  #   false → address is loopback, private, link-local, or otherwise reserved
  class AddressPolicy
    # IPv4 ranges that must never be treated as public.
    # Written in CIDR form: "address/prefix" means "this network and every
    # address that shares the first N bits" (the number after / is N).
    #
    # Examples:
    #   10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16  → home/office private LANs
    #   127.0.0.0/8                                 → "this computer" (localhost)
    #   169.254.0.0/16                              → link-local; also covers
    #                                                 AWS/GCP/Azure metadata IPs
    #   224.0.0.0/4, 240.0.0.0/4                    → multicast / future-use
    #   192.0.2.0/24, 198.51.100.0/24, 203.0.113.0/24 → documentation-only
    BLOCKED_IPV4 = %w[
      0.0.0.0/8
      10.0.0.0/8
      100.64.0.0/10
      127.0.0.0/8
      169.254.0.0/16
      172.16.0.0/12
      192.0.0.0/24
      192.0.2.0/24
      192.88.99.0/24
      192.168.0.0/16
      198.18.0.0/15
      198.51.100.0/24
      203.0.113.0/24
      224.0.0.0/4
      240.0.0.0/4
    ].freeze

    # Same idea for IPv6. Highlights:
    #   ::1/128        → IPv6 localhost
    #   fc00::/7       → unique-local (IPv6's "private" range)
    #   fe80::/10      → link-local
    #   ff00::/8       → multicast
    #   2001:db8::/32  → documentation-only
    #   64:ff9b::/96   → NAT64 well-known prefix (not a public host)
    BLOCKED_IPV6 = %w[
      ::/128
      ::1/128
      fc00::/7
      fe80::/10
      ff00::/8
      2001:db8::/32
      64:ff9b::/96
    ].freeze

    def self.call(ip)
      new(ip).call
    end

    def initialize(ip)
      @ip = ip
    end

    # true = reachable-and-public; false = blocked / not public.
    def call
      # Unwrap "IPv4 stuffed inside IPv6" so it can match BLOCKED_IPV4.
      #   ::ffff:127.0.0.1  is IPv4-mapped IPv6 — same machine as 127.0.0.1.
      #   #native turns mapped/compatible addresses into plain IPv4 (Ruby 3.4.10+).
      address = normalize(@ip)

      # Single source of truth: BLOCKED_IPV4 / BLOCKED_IPV6 already include
      # loopback, RFC1918, link-local, plus docs/multicast/CGNAT/etc.
      !blocked_by_cidr?(address)
    end

    private

    # Prefer a native IPv4 view when the address is IPv4-mapped (or compatible).
    # Otherwise leave it alone (plain IPv4 or plain IPv6).
    def normalize(ip)
      if ip.ipv4_mapped? || (ip.respond_to?(:ipv4_compat?) && ip.ipv4_compat?)
        ip.native
      else
        ip
      end
    end

    # Does this address fall inside any BLOCKED_* CIDR for its family?
    def blocked_by_cidr?(address)
      ranges_for(address).any? { |range| range.include?(address) }
    end

    # Pick the IPv4 or IPv6 block list so we never mix families.
    def ranges_for(address)
      address.ipv4? ? blocked_ipv4_ranges : blocked_ipv6_ranges
    end

    # Parse CIDR strings once into IPAddr network objects (cheap to reuse).
    def blocked_ipv4_ranges
      @blocked_ipv4_ranges ||= BLOCKED_IPV4.map { |cidr| IPAddr.new(cidr) }
    end

    def blocked_ipv6_ranges
      @blocked_ipv6_ranges ||= BLOCKED_IPV6.map { |cidr| IPAddr.new(cidr) }
    end
  end
end

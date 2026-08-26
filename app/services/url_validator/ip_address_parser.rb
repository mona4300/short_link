require "ipaddr"
require "socket"

class UrlValidator
  # Turns "weird number spellings" of an IP into a normal IPAddr.
  #
  # Why this exists:
  #   Browsers/OS accept hosts like "2130706433" or "127.1" as 127.0.0.1.
  #   Ruby's IPAddr does not — so without this, those look like hostnames
  #   and can slip past "reject IP addresses" checks.
  #
  # Returns:
  #   IPAddr  → host was an IP (possibly obfuscated)
  #   nil     → host looks like a real name (example.com) or is not numeric
  class IpAddressParser
    # Number bases attackers use to disguise the same IP:
    #   hex     "0x7f"     → 127  (0x = hexadecimal)
    #   octal   "0177"     → 127  (leading 0 = octal, digits 0–7 only)
    #   decimal "127"      → 127  (everyday base-10)
    # "08" matches none (8 is invalid in octal; leading 0 blocks decimal) → rejected.
    HEX = /\A0[xX][0-9a-fA-F]+\z/
    OCTAL = /\A0[0-7]*\z/
    DECIMAL = /\A(?:0|[1-9][0-9]*)\z/

    # IPv4 is always one 32-bit number. With fewer than 4 dotted parts,
    # the last part is allowed to be wider (it fills the leftover bits).
    # Each entry is the max exclusive value for that part — same rules as C's inet_aton.
    #
    #   1 part  "2130706433"     → whole 32-bit address
    #   2 parts "127.1"          → byte + remaining 24 bits → 127.0.0.1
    #   3 parts "127.0.1"        → two bytes + remaining 16 bits → 127.0.0.1
    #   4 parts "127.0.0.1"      → four normal bytes
    PART_LIMITS = {
      1 => [ 2**32 ],
      2 => [ 2**8, 2**24 ],
      3 => [ 2**8, 2**8, 2**16 ],
      4 => [ 2**8 ] * 4
    }.freeze

    # Where each part sits inside the 32-bit address (bit positions from the left).
    # Example for "127.1" with shifts [24, 0]:
    #   127 << 24 | 1 << 0  →  127.0.0.1
    PART_SHIFTS = {
      1 => [ 0 ],
      2 => [ 24, 0 ],
      3 => [ 24, 16, 0 ],
      4 => [ 24, 16, 8, 0 ]
    }.freeze

    def self.call(host)
      new(host).call
    end

    def initialize(host)
      @host = host.to_s
    end

    def call
      # URLs write IPv6 in brackets: "[::1]". Strip them so IPAddr can read it.
      unwrapped = @host.delete_prefix("[").delete_suffix("]")

      # IPv6 always contains ":". Hand those to Ruby; we only decode weird IPv4 forms ourselves.
      return parse_ipv6(unwrapped) if unwrapped.include?(":")

      parse_ipv4(unwrapped)
    end

    private

    # Ruby already understands normal IPv6 text (::1, ::ffff:127.0.0.1).
    # Invalid IPv6 → nil (treat as "not an IP we recognized").
    def parse_ipv6(host)
      IPAddr.new(host)
    rescue IPAddr::InvalidAddressError
      nil
    end

    def parse_ipv4(host)
      # Step 1: split on "." into 1–4 pieces.
      # -1 keeps empty trailing parts so "127.0.0.1." (5 pieces) is rejected, not silently fixed.
      parts = host.split(".", -1)
      return nil unless PART_LIMITS.key?(parts.size)

      # Step 2: each piece must be a number (hex / octal / decimal).
      # "example.com" → ["example","com"] → nil (hostname, not an IP).
      # "1e2" → no part matches → nil (scientific notation is not inet_aton).
      values = parts.map { |part| parse_part(part) }
      return nil if values.any?(&:nil?)

      # Step 3: each number must fit the width allowed for its position.
      # e.g. in 4-part form, every part must be < 256.
      limits = PART_LIMITS.fetch(parts.size)
      shifts = PART_SHIFTS.fetch(parts.size)
      return nil if values.zip(limits).any? { |value, limit| value >= limit }

      # Step 4: pack the pieces into one 32-bit integer, then wrap as IPAddr.
      # "127.0.0.1" → zip with [24,16,8,0], OR shifted octets → one integer.
      # "2130706433" → one part, shift [0] → address stays 2130706433 (already the
      # full 32-bit value; same bits as 127.0.0.1).
      # Socket::AF_INET = address family IPv4 — tells IPAddr the integer is 32-bit IPv4
      # (not IPv6). Without it, a bare integer is ambiguous.
      address = values.zip(shifts).reduce(0) { |acc, (value, shift)| acc | (value << shift) }
      IPAddr.new(address, Socket::AF_INET)
    end

    # Decode one dotted piece into an Integer, or nil if it is not a number form we accept.
    def parse_part(part)
      if part.match?(HEX)
        Integer(part, 16)   # "0x7f" → 127
      elsif part.match?(OCTAL)
        Integer(part, 8)    # "0177" → 127
      elsif part.match?(DECIMAL)
        Integer(part, 10)   # "127"  → 127
      end
    end
  end
end

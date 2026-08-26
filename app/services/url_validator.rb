require "uri"

class UrlValidator
  attr_reader :error, :error_message, :normalized_url

  ALLOWED_SCHEMES = %w[http https].freeze

  # RFC 6761 loopback name: always resolves back to the machine itself.
  LOCALHOST_NAMES = %w[localhost].freeze

  # Names that are never public internet destinations (intranet / reserved DNS).
  INTERNAL_HOST_NAMES = %w[
    internal
    local
    home.arpa
    lan
    corp
    intranet
    test
    example
    invalid
  ].freeze

  # One DNS label: letters/digits/hyphen only (LDH), 1–63 chars, no leading/trailing hyphen.
  LDH_LABEL = /\A[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\z/i

  MAX_HOST_BYTES = 253

  def initialize(url)
    # Coerce here so a non-string param (url[]=a&url[]=b) fails validation
    # instead of raising.
    @url = url.to_s
  end

  def valid?
    return fail_with(:blank) if @url.blank?
    return fail_with(:too_long) if @url.bytesize > ShortLink::MAX_ORIGINAL_LINK_LENGTH

    uri = parse_uri
    host = normalize_host(uri&.host)

    error = detect_error(uri, host)
    return fail_with(error) if error

    @normalized_url = build_normalized_url(uri, host)
    true
  end

  private

  # Each step returns an error code or nil, so the first failing layer wins.
  def detect_error(uri, host)
    uri_error(uri) || host_error(host) || port_error(uri) || address_error(host)
  end

  def uri_error(uri)
    # Missing scheme/host → :invalid (preserves "not-a-url"); wrong scheme → :invalid_scheme.
    return :invalid if uri.nil? || uri.scheme.blank? || uri.host.blank?
    return :invalid_scheme unless ALLOWED_SCHEMES.include?(uri.scheme)

    # Embedded credentials (https://user:pass@host/) would be stored and then
    # handed back out by the short link.
    :userinfo if uri.userinfo.present?
  end

  # Ordered so the specific reason wins over the generic one: IP literals and
  # reserved names are reported before the LDH/TLD hostname rules, which would
  # otherwise swallow single-label names such as "localhost" as :invalid_host.
  def host_error(host)
    return :idn_host if idn_host?(host)
    return :ip_address if IpAddressParser.call(host)
    return :localhost if reserved_host?(host, LOCALHOST_NAMES)
    return :internal_host if reserved_host?(host, INTERNAL_HOST_NAMES)

    :invalid_host unless valid_hostname?(host)
  end

  def port_error(uri)
    :custom_port if uri.port != uri.default_port
  end

  def address_error(host)
    addresses = DnsResolver.resolve(host)
    :private_address unless addresses.all? { |ip| AddressPolicy.call(ip) }
  rescue DnsResolver::Error
    :unresolvable_host
  end

  def parse_uri
    URI.parse(@url)
  rescue URI::InvalidURIError
    nil
  end

  # Downcase and strip a trailing FQDN dot so later checks see one form.
  #
  # A trailing "." marks an absolute DNS name ("this name is complete; do not
  # append a local search suffix"). Without it, some machines may treat a host
  # as relative and try e.g. example.com.company.local before public DNS.
  # Browsers and paste sources can still submit either form; both should be the
  # same short-link destination, so we normalize "example.com." → "example.com".
  def normalize_host(host)
    host.to_s.downcase.delete_suffix(".")
  end

  # Non-ASCII labels, or any punycode (xn--) label — blocked rather than decoded.
  # Example: http://еxample.com  => http://xn--xample-2of.com/
  def idn_host?(host)
    !host.ascii_only? || host.split(".").any? { |label| label.start_with?("xn--") }
  end

  # Matches the name itself or any subdomain of it.
  def reserved_host?(host, names)
    names.any? { |name| host == name || host.end_with?(".#{name}") }
  end

  # Requires LDH labels and an alphabetic TLD (also rejects single-label intranet names).
  def valid_hostname?(host)
    # DNS caps the full hostname at 253 bytes.
    return false if host.bytesize > MAX_HOST_BYTES

    # Split into labels: "www.example.com" → ["www", "example", "com"].
    # -1 keeps empty trailing parts so "example.com." (if not normalized) fails cleanly.
    labels = host.split(".", -1)

    # Need at least two labels (name + TLD). Rejects bare names like "intranet".
    return false if labels.size < 2

    # Every label must be LDH: letters/digits/hyphen only, 1–63 chars,
    # no leading/trailing hyphen (see LDH_LABEL).
    return false unless labels.all? { |label| label.match?(LDH_LABEL) }

    # Final label (TLD = Top-Level Domain, e.g. "com") must contain a letter —
    # rejects all-numeric endings.
    labels.last.match?(/[a-z]/i)
  end

  # Rebuild one canonical string from already-validated pieces.
  # Example: HTTPS://Example.COM.:443/Path?q=1#top
  #       → https://example.com/Path?q=1#top
  # Host is the normalized form (lowercase, no trailing dot). Path/query/fragment
  # stay as submitted except @ encoding. No extra trailing slash; port is omitted
  # because custom ports were already rejected, so only the scheme default remains.
  def build_normalized_url(uri, host)
    path = encode_at(uri.path.to_s)
    query = uri.query && "?#{encode_at(uri.query)}"
    fragment = uri.fragment && "##{encode_at(uri.fragment)}"

    "#{uri.scheme}://#{host}#{path}#{query}#{fragment}"
  end

  # @ after the host is data, not a login separator. A later bad parse of
  # https://google.com#@evil.com may treat @ as "real host is evil.com"
  # (spoofing: one string, two destinations). %40 is still "@" as text, but
  # it cannot be read as the userinfo/host switch.
  def encode_at(value)
    value.gsub("@", "%40")
  end

  def fail_with(error)
    @error = error
    @error_message = I18n.t("url_validator.errors.#{error}")
    false
  end
end

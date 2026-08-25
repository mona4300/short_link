class ShortLinkEncoder
  MAX_ATTEMPTS = 5

  def initialize(url)
    @url = url
  end

  def call
    attempts = 0

    begin
      attempts += 1
      ShortLink.create!(original_link: @url, code: generate_code)
    rescue ActiveRecord::RecordNotUnique
      retry if attempts < MAX_ATTEMPTS
      raise
    end
  end

  private

  def generate_code
    SecureRandom.alphanumeric(ShortLink::CODE_LENGTH)
  end
end

class ShortLinkEncoder
  MAX_ATTEMPTS = 5

  attr_reader :short_link

  def initialize(url)
    @url = url
    @validator = UrlValidator.new(url)
  end

  def valid?
    @validator.valid?
  end

  def call
    raise_validation_error unless valid?

    attempts = 0

    begin
      attempts += 1
      @short_link = ShortLink.create!(original_link: @validator.normalized_url, code: generate_code)
    rescue ActiveRecord::RecordNotUnique
      retry if attempts < MAX_ATTEMPTS
      raise CodeCollisionError
    rescue ActiveRecord::RecordInvalid => e
      raise_record_invalid_error(e)
    end

    @short_link
  end

  private

  def raise_validation_error
    raise EncoderError.new(
      error_code: @validator.error,
      message: @validator.error_message
    )
  end

  def raise_record_invalid_error(exception)
    raise EncoderError.new(
      error_code: :invalid,
      message: exception.record.errors.full_messages.first
    )
  end

  def generate_code
    SecureRandom.alphanumeric(ShortLink::CODE_LENGTH)
  end
end

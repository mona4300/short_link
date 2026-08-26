class EncoderError < StandardError
  attr_reader :error_code, :message

  def initialize(error_code:, message:)
    @error_code = error_code
    @message = message
    super(message)
  end
end

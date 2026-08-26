class CodeCollisionError < EncoderError
  def initialize
    super(
      error_code: :code_collision,
      message: "Unable to generate a unique short link. Please try again."
    )
  end
end

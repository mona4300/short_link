class ShortLink < ApplicationRecord
  MAX_ORIGINAL_LINK_LENGTH = 2048
  # Max possible values: 62^10 = 839,299,365,868,340,224 (A-Za-z0-9)
  CODE_LENGTH = 10
  CODE_FORMAT = /\A[A-Za-z0-9]+\z/

  validates :original_link, presence: true, length: { maximum: MAX_ORIGINAL_LINK_LENGTH }
  validates :code, presence: true, length: { is: CODE_LENGTH }, format: { with: CODE_FORMAT }
end

require "rails_helper"

RSpec.describe ShortLink, type: :model do
  describe "validations" do
    subject(:short_link) { build(:short_link) }

    it { is_expected.to validate_presence_of(:original_link) }
    it { is_expected.to validate_length_of(:original_link).is_at_most(ShortLink::MAX_ORIGINAL_LINK_LENGTH) }

    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_length_of(:code).is_equal_to(ShortLink::CODE_LENGTH) }
    it { is_expected.to allow_value("abc1234567").for(:code) }
    it { is_expected.to allow_value("AbC0zY9xW1").for(:code) }
    it { is_expected.not_to allow_value("abc123456_").for(:code) }
  end
end

require "rails_helper"

RSpec.describe "Decode routing", type: :routing do
  it "routes GET /decode/:code to short_links#show" do
    expect(get: "/decode/abc1234567").to route_to(
      controller: "short_links",
      action: "show",
      code: "abc1234567"
    )
  end
end

require "rails_helper"

RSpec.describe "Decode routing", type: :routing do
  it "routes POST /decode to decodings#create" do
    expect(post: "/decode").to route_to(
      controller: "decodings",
      action: "create"
    )
  end
end

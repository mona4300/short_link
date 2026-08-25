require "rails_helper"

RSpec.describe "Encode routing", type: :routing do
  it "routes POST /encode to encodings#create" do
    expect(post: "/encode").to route_to(
      controller: "encodings",
      action: "create"
    )
  end
end

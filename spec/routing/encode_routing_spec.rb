require "rails_helper"

RSpec.describe "Encode routing", type: :routing do
  it "routes POST /encode to short_links#create" do
    expect(post: "/encode").to route_to(
      controller: "short_links",
      action: "create"
    )
  end
end

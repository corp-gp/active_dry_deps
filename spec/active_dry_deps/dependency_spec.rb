# frozen_string_literal: true

RSpec.describe ActiveDryDeps::Dependency do
  it "loads constant" do
    dependency = described_class.new("CreateDeparture")
    expect(dependency.const_get).to eq CreateDeparture
  end
end

# frozen_string_literal: true

RSpec.describe ActiveDryDeps::DependencyMap do
  describe "#check_cyclic_references" do
    it "checks circular dependencies" do
      dependency_map = described_class.new
      dependency_map.register("CreateDeparture", %w[CreateOrder])
      dependency_map.register("CreateOrder", %w[CreateDeparture])

      expect { dependency_map.check_cyclic_references }.to raise_error(ActiveDryDeps::CircularDependency, <<~TEXT)
        Expected the dependency graph to be acyclic, but it contains the following circular dependencies:
        CreateDeparture → CreateOrder → CreateDeparture
      TEXT
    end
  end
end

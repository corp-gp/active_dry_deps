# frozen_string_literal: true

namespace :active_dry_deps do
  desc 'Check dependency graph'
  task check_cyclic_references: :environment do
    dependency_map = ActiveDryDeps::DependencyMap.new

    ActiveDryDeps::Deps.subscribe(:included_dependency) do |event|
      dependency_map.register(event[:receiver], event[:dependencies].map(&:name))
    end

    require Rails.root.join('config/environment.rb')

    dependency_map.check_cyclic_references
  end
end

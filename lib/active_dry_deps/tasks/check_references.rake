# frozen_string_literal: true

namespace :active_dry_deps do
  desc 'Check dependency graph'
  task :check_references, :environment do |task|
    dependency_map = ActiveDryDeps::DependencyMap.new

    ActiveDryDeps::Deps.subscribe(:included_dependency) do |event|
      dependency_map.register(event[:receiver], event[:dependencies])
    end

    require File.join(task.application.original_dir, "config/environment.rb")

    dependency_map.check_references
  end
end
# frozen_string_literal: true

module ActiveDryDeps
  class Railtie < ::Rails::Railtie

    config.to_prepare do
      Object.const_set(ActiveDryDeps.config.inject_global_constant, ::ActiveDryDeps::Deps)
      ActiveDryDeps.config.finalize!(freeze_values: true)
    end

    rake_tasks do
      path = File.expand_path(__dir__)
      Dir.glob("#{path}/tasks/**/*.rake").each { |f| load f }
    end

  end
end

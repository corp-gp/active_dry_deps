# frozen_string_literal: true

module ActiveDryDeps
  class Railtie < ::Rails::Railtie

    config.after_initialize do
      app_namespace = ::Rails.application.class.to_s.split('::').first
      ActiveDryDeps.config.container ||= "#{app_namespace}::Container"

      require_relative 'deps'

      Object.const_set(ActiveDryDeps.config.inject_global_constant, ::ActiveDryDeps::Deps)
      ActiveDryDeps.config.finalize!(freeze_values: true)
    end

  end
end

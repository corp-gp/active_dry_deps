# frozen_string_literal: true

module ActiveDryDeps
  class Railtie < ::Rails::Railtie

    config.to_prepare do
      Object.const_set(ActiveDryDeps.config.inject_global_constant, ::ActiveDryDeps::Deps)
      ActiveDryDeps.config.finalize!(freeze_values: true)
    end

  end
end

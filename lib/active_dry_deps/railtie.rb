# frozen_string_literal: true

module ActiveDryDeps
  class Railtie < ::Rails::Railtie

    config.to_prepare do
      const_name = ActiveDryDeps.config.inject_global_constant
      Object.send(:remove_const, const_name) if Object.const_defined?(const_name)
      Object.const_set(const_name, ::ActiveDryDeps::Deps)

      ActiveDryDeps.config.finalize!(freeze_values: true)
    end

  end
end

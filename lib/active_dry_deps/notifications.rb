# frozen_string_literal: true

require 'dry-monitor'

module ActiveDryDeps
  module Notifications

    module_function

    EVENT_BUS = Dry::Monitor::Notifications.new("active_dry_deps.monitor").tap do |notifications|
      notifications.register_event(:included_dependency)
    end

    def included_dependency_decorator(dependencies)
      Module.new.tap do |m|
        m.define_singleton_method(:included) do |enum_module|
          enum_module.define_singleton_method(:included) do |enum_receiver|
            EVENT_BUS.instrument(:included_dependency, receiver: enum_receiver.name, dependencies: dependencies)
          end
        end
      end
    end

    module ClassMethods

      def subscribe(*args, **options, &block)
        EVENT_BUS.subscribe(*args, **options, &block)
      end

    end

  end
end

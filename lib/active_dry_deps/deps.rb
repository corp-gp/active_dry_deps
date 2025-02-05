# frozen_string_literal: true

module ActiveDryDeps
  module Deps

    CONTAINER = Container.new

    extend Notifications::ClassMethods

    module_function

    # include Deps[routes_admin: 'Lib::Routes.admin'] use as `routes_admin`
    # include Deps['Lib::Routes.admin'] use as `admin`
    # include Deps['Lib::Routes'] use as `Routes()`
    # include Deps['OrderService::Recalculate.call'] use as `Recalculate()`
    def [](*keys, **aliases)
      m = Module.new

      dependencies  = keys.map { |resolver| Dependency.new(resolver) }
      dependencies += aliases.map { |alias_method, resolver| Dependency.new(resolver, receiver_method_alias: alias_method) }

      m.module_eval(dependencies.map(&:receiver_method_string).join("\n"))
      m.include(Notifications.included_dependency_decorator(dependencies))
      m
    end

    def register(...)
      CONTAINER.register(...)
    end

  end
end

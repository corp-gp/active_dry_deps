# frozen_string_literal: true

module ActiveDryDeps
  module Deps

    extend Notifications::ClassMethods

    module_function

    # include Deps[routes_admin: 'Lib::Routes.admin'] use as `routes_admin`
    # include Deps['Lib::Routes.admin'] use as `admin`
    # include Deps['Lib::Routes'] use as `Routes()`
    # include Deps['OrderService::Recalculate.call'] use as `Recalculate()`
    def [](*keys, **aliases)
      m = Module.new
      dependencies = []

      dependencies +=
        keys.map do |resolver|
          Dependency.new(resolver).tap do |dependency|
            m.define_method(dependency.receiver_method_name, &dependency.receiver_method)
          end
        end

      dependencies +=
        aliases.map do |alias_method, resolver|
          Dependency.new(resolver, receiver_method_alias: alias_method).tap do |dependency|
            m.define_method(dependency.receiver_method_name, &dependency.receiver_method)
          end
        end

      m.include(Notifications.included_dependency_decorator(dependencies))
      m
    end

    def resolve(key)
      CONTAINER[resolve_key(key)]
    end

    def resolve_key(key)
      ActiveDryDeps.config.inflector.underscore(key).tr('/', '.')
    end

    def self.const_missing(const_name)
      return super unless const_name == :CONTAINER

      Deps.const_set(:CONTAINER, Object.const_get(ActiveDryDeps.config.container))
    end

  end
end

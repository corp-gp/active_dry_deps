# frozen_string_literal: true

module ActiveDryDeps
  module Deps

    CONTAINER = Container.new

    module_function

    # include Deps[routes_admin: 'Lib::Routes.admin'] use as `routes_admin`
    # include Deps['Lib::Routes.admin'] use as `admin`
    # include Deps['Lib::Routes'] use as `Routes()`
    # include Deps['OrderService::Recalculate.call'] use as `Recalculate()`
    def [](*keys, **aliases)
      m = Module.new

      receiver_methods = +''

      keys.each do |resolver|
        receiver_methods << Dependency.new(resolver).receiver_method_string << "\n"
      end

      aliases.each do |alias_method, resolver|
        receiver_methods << Dependency.new(resolver, receiver_method_alias: alias_method).receiver_method_string << "\n"
      end

      m.module_eval(receiver_methods)
      m
    end

    def register(...)
      CONTAINER.register(...)
    end

  end
end

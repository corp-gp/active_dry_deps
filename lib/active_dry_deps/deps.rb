# frozen_string_literal: true

module ActiveDryDeps
  module Deps

    CONTAINER = Container.new

    module_function

    # include Deps[routes_admin: 'Lib::Routes.admin'] use as `routes_admin`
    # include Deps['Lib::Routes.admin'] use as `admin`
    # include Deps['Lib::Routes'] use as `Routes()`
    # include Deps['OrderService::Recalculate.call'] use as `Recalculate()`
    # include Deps[send_email: -> { 'email-sent' }] use as `send_email`
    def [](*keys, **aliases)
      m = Module.new

      dependencies = []
      dependencies += keys.map { |resolver| Dependency.new(resolver) }
      dependencies += aliases.map { |alias_method, resolver| Dependency.new(resolver, receiver_method_alias: alias_method) }

      call_dependencies, constant_dependencies = dependencies.partition(&:callable?)

      m.module_eval(constant_dependencies.map(&:receiver_method_string).join("\n"))

      call_dependencies.each do |dependency|
        m.define_method(dependency.receiver_method_name, &dependency.receiver_method)
      end

      m
    end

    # TODO: необходимость сомнительна
    def resolve(resolver)
      dependency = Dependency.new(resolver)
      m = Module.new { module_function module_eval(dependency.receiver_method_string) }
      m.public_send(dependency.receiver_method_name)
    end

  end
end

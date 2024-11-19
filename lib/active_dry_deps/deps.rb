# frozen_string_literal: true

module ActiveDryDeps
  module Deps

    extend Notifications::ClassMethods

    VALID_NAME = /([a-zA-Z_0-9]*)$/
    METHODS_AS_KLASS = %w[perform_later call].freeze

    module_function

    # include Deps[routes_admin: 'Lib::Routes.admin'] use as `routes_admin`
    # include Deps['Lib::Routes.admin'] use as `admin`
    # include Deps['Lib::Routes'] use as `Routes()`
    # include Deps['OrderService::Recalculate.call'] use as `Recalculate()`
    def [](*keys, **aliases)
      str_methods = +''
      dependencies = []

      keys.each do |resolver|
        dependency_name, str_method = fetch_dependency(resolver, nil)
        dependencies << dependency_name
        str_methods << str_method
      end

      aliases.each do |alias_method, resolver|
        dependency_name, str_method = fetch_dependency(resolver, alias_method)
        dependencies << dependency_name
        str_methods << str_method
      end

      m = Module.new
      m.module_eval(str_methods)
      m.include(Notifications.included_dependency_decorator(dependencies))
      m
    end

    def resolve(key)
      container[resolve_key(key)]
    end

    def resolve_key(key)
      ActiveDryDeps.config.inflector.underscore(key).tr('/', '.')
    end

    def container
      return Deps.const_get(:CONTAINER) if Deps.const_defined?(:CONTAINER)

      Deps.const_set(:CONTAINER, Object.const_get(ActiveDryDeps.config.container))
    end

    private_class_method def fetch_dependency(resolve, alias_method)
      resolve_klass, extract_method = resolve.split('.')

      alias_method ||=
        if extract_method && METHODS_AS_KLASS.exclude?(extract_method)
          extract_method
        else
          resolve_klass.split('::').last
        end

      if alias_method && !VALID_NAME.match?(alias_method.to_s)
        raise DependencyNameInvalid, "name +#{alias_method}+ is not a valid Ruby identifier"
      end

      key = resolve_key(resolve_klass)

      str_method =
        if extract_method
          %(def #{alias_method}(...); ::#{ActiveDryDeps.config.container}['#{key}'].#{extract_method}(...) end\n)
        else
          %(def #{alias_method}; ::#{ActiveDryDeps.config.container}['#{key}'] end\n)
        end

      [resolve_klass, str_method]
    end

  end
end

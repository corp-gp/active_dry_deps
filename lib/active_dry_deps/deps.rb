# frozen_string_literal: true

module ActiveDryDeps
  module Deps

    VALID_NAME = /([a-zA-Z_0-9]*)$/
    METHODS_AS_KLASS = %w[perform_later call].freeze

    module_function

    # include Deps[routes_admin: 'Lib::Routes.admin'] use as `routes_admin`
    # include Deps['Lib::Routes.admin'] use as `admin`
    # include Deps['Lib::Routes'] use as `Routes()`
    # include Deps['OrderService::Recalculate.call'] use as `Recalculate()`
    def [](*keys, **aliases)
      str_methods = +''

      keys.each { |resolver| str_methods << str_method(resolver, nil) }
      aliases.each { |alias_method, resolver| str_methods << str_method(resolver, alias_method) }

      m = Module.new
      m.module_eval(str_methods)
      m
    end

    private def str_method(resolve, alias_method)
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

      key = ActiveDryDeps.config.inflector.underscore(resolve_klass).tr('/', '.')

      if extract_method
        %(def #{alias_method}(...); ::#{ActiveDryDeps.config.container}['#{key}'].#{extract_method}(...) end\n)
      else
        %(def #{alias_method}; ::#{ActiveDryDeps.config.container}['#{key}'] end\n)
      end
    end

    def resolve_key(key)
      if key.include?('::')
        ActiveDryDeps.config.inflector.underscore(key).tr('/', '.')
      else
        key
      end
    end

    instance_eval <<~RUBY, __FILE__, __LINE__ + 1
      # def resolve(key)
      #   ::MyApp::Container[resolve_key(key)]
      # end

      def resolve(key)
        ::#{ActiveDryDeps.config.container}[resolve_key(key)]
      end
    RUBY

  end
end

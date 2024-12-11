# frozen_string_literal: true

module ActiveDryDeps
  class Dependency

    LOWER = /[[:lower:]]/

    attr_reader :receiver_method_name, :resolve_key, :const_name, :method_name

    def initialize(resolver, receiver_method_alias: nil)
      if LOWER.match?(resolver[0])
        receiver_method_by_key(resolver, receiver_method_alias: receiver_method_alias)
      else
        receiver_method_by_const_name(resolver, receiver_method_alias: receiver_method_alias)
      end
    end

    if Rails.env.test?
      def receiver_method_string
        Kernel.sprintf(
          METHOD_TEMPLATES.fetch(container: true, method_call: !@method_name.nil?),
          receiver_method_name:        @receiver_method_name,
          container_key_or_const_name: @const_name || @resolve_key,
          method_name:                 @method_name,
        )
      end
    else
      def receiver_method_string
        Kernel.sprintf(
          METHOD_TEMPLATES.fetch(container: !@resolve_key.nil?, method_call: !@method_name.nil?),
          receiver_method_name:        @receiver_method_name,
          container_key_or_const_name: @const_name || @resolve_key,
          method_name:                 @method_name,
        )
      end
    end

    VALID_METHOD_NAME = /^[[[:alnum:]]_]+$/

    private def receiver_method_by_key(resolver, receiver_method_alias: nil)
      receiver_method_name = receiver_method_alias || resolver

      unless VALID_METHOD_NAME.match?(receiver_method_name.to_s)
        raise DependencyNameInvalid, "name +#{receiver_method_name}+ is not a valid Ruby identifier"
      end

      @receiver_method_name = receiver_method_name.to_sym
      @resolve_key = resolver
    end

    VALID_CONST_NAME  = /^[[:upper:]][[[:alnum:]]:_]*$/
    METHODS_AS_KLASS  = %w[perform_later call].freeze

    private def receiver_method_by_const_name(resolver, receiver_method_alias: nil)
      const_name, method_name = resolver.to_s.split('.', 2)

      unless VALID_CONST_NAME.match?(const_name)
        raise DependencyNameInvalid, "+#{resolver}+ must contains valid constant name"
      end

      if method_name && !VALID_METHOD_NAME.match?(method_name)
        raise DependencyNameInvalid, "name +#{method_name}+ is not a valid Ruby identifier"
      end

      receiver_method_name =
        if receiver_method_alias
          receiver_method_alias
        elsif method_name && METHODS_AS_KLASS.exclude?(method_name)
          method_name
        elsif const_name
          const_name.split('::').last
        else
          resolver
        end

      unless VALID_METHOD_NAME.match?(receiver_method_name.to_s)
        raise DependencyNameInvalid, "name +#{receiver_method_name}+ is not a valid Ruby identifier"
      end

      @receiver_method_name = receiver_method_name.to_sym
      @const_name = const_name
      @method_name = method_name&.to_sym
    end

    METHOD_TEMPLATES = {
      { container: true, method_call: true }   => <<~RUBY,
        # def CreateOrder(...)
        #   ::ActiveDryDeps::Deps::CONTAINER.resolve("OrderService::Create").call(...)
        # end

        def %<receiver_method_name>s(...)
          ::ActiveDryDeps::Deps::CONTAINER.resolve("%<container_key_or_const_name>s").%<method_name>s(...)
        end
      RUBY
      { container: true, method_call: false }  => <<~RUBY,
        # def CreateOrder
        #   ::ActiveDryDeps::Deps::CONTAINER.resolve("OrderService::Create")
        # end

        def %<receiver_method_name>s
          ::ActiveDryDeps::Deps::CONTAINER.resolve("%<container_key_or_const_name>s")
        end
      RUBY
      { container: false, method_call: true }  => <<~RUBY,
        # def CreateOrder(...)
        #   OrderService::Create.call(...)
        # end

        def %<receiver_method_name>s(...)
          %<container_key_or_const_name>s.%<method_name>s(...)
        end
      RUBY
      { container: false, method_call: false } => <<~RUBY,
        # def CreateOrder
        #   OrderService::Create
        # end

        def %<receiver_method_name>s
          %<container_key_or_const_name>s
        end
      RUBY
    }.freeze

  end
end

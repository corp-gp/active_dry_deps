# frozen_string_literal: true

module ActiveDryDeps
  class Dependency

    VALID_METHOD_NAME = /^[a-zA-Z_0-9]+$/
    VALID_CONST_NAME  = /^[[:upper:]][a-zA-Z_0-9\:]*$/
    METHODS_AS_KLASS  = %w[perform_later call].freeze

    attr_reader :receiver_method_name, :receiver_method, :const_name, :method_name

    def initialize(resolver, receiver_method_alias: nil)
      if resolver.respond_to?(:call)
        receiver_method_by_proc(resolver, receiver_method_alias: receiver_method_alias)
      else
        receiver_method_by_const_name(resolver, receiver_method_alias: receiver_method_alias)
      end
    end

    def callable?
      !@receiver_method.nil?
    end

    def receiver_method_string
      if @method_name
        <<~RUBY
          # def create_order(*args, **options, &block)
          #   ::ActiveDryDeps::Deps::CONTAINER.resolve("OrderService::Create").call(*args, **options, &block)
          # end

          def #{@receiver_method_name}(*args, **options, &block)
            ::ActiveDryDeps::Deps::CONTAINER.resolve("#{@const_name}").#{@method_name}(*args, **options, &block)
          end
        RUBY
      else
        <<~RUBY
          # def create_order_service
          #   ::ActiveDryDeps::Deps::CONTAINER.resolve("OrderService::Create")
          # end

          def #{@receiver_method_name}
            ::ActiveDryDeps::Deps::CONTAINER.resolve("#{@const_name}")
          end
        RUBY
      end
    end

    private def receiver_method_by_proc(resolver, receiver_method_alias: nil)
      unless receiver_method_alias
        raise MissingAlias, 'Alias is required while injecting with Proc'
      end

      @receiver_method_name = receiver_method_alias

      unless VALID_METHOD_NAME.match?(@receiver_method_name.to_s)
        raise DependencyNameInvalid, "name +#{@receiver_method_name}+ is not a valid Ruby identifier"
      end

      @receiver_method = resolver
    end

    private def receiver_method_by_const_name(resolver, receiver_method_alias: nil)
      @const_name, @method_name = resolver.to_s.split('.', 2)

      unless VALID_CONST_NAME.match?(@const_name)
        raise DependencyNameInvalid, "+#{resolver}+ must contains valid constant name"
      end

      if @method_name && !VALID_METHOD_NAME.match?(@method_name)
        raise DependencyNameInvalid, "name +#{@method_name}+ is not a valid Ruby identifier"
      end

      @receiver_method_name =
        if receiver_method_alias
          receiver_method_alias
        elsif @method_name && METHODS_AS_KLASS.exclude?(@method_name)
          @method_name
        elsif @const_name
          @const_name.split('::').last
        else
          resolver
        end

      unless VALID_METHOD_NAME.match?(@receiver_method_name.to_s)
        raise DependencyNameInvalid, "name +#{@receiver_method_name}+ is not a valid Ruby identifier"
      end
    end

  end
end

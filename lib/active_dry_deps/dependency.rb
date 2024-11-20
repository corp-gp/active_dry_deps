# frozen_string_literal: true

module ActiveDryDeps
  class Dependency

    VALID_METHOD_NAME = /^[a-zA-Z_0-9]+$/
    VALID_CONST_NAME  = /^[[:upper:]][a-zA-Z_0-9\:]*$/
    METHODS_AS_KLASS  = %w[perform_later call].freeze

    attr_reader :name, :receiver_method_name, :resolved_key, :const_name, :method_name

    def initialize(resolver, receiver_method_alias: nil)
      extracted_dependency_name, extracted_method_name, rest = resolver.to_s.split('.', 3)

      extracted_const_name =
        if VALID_CONST_NAME.match?(extracted_dependency_name)
          extracted_dependency_name
        end

      if rest || (extracted_method_name && !extracted_const_name)
        raise DependencyNameInvalid, "+#{resolver}+ must contains a class/module name. Make sure not use dot-notation 'a.b.c'"
      end

      receiver_method_name =
        if receiver_method_alias
          receiver_method_alias
        elsif extracted_method_name && METHODS_AS_KLASS.exclude?(extracted_method_name)
          extracted_method_name
        elsif extracted_const_name
          extracted_const_name.split('::').last
        else
          resolver
        end

      unless VALID_METHOD_NAME.match?(receiver_method_name.to_s)
        raise DependencyNameInvalid, "name +#{receiver_method_name}+ is not a valid Ruby identifier"
      end

      @name = extracted_dependency_name
      @receiver_method_name = receiver_method_name.to_sym
      @resolved_key = Deps.resolve_key(extracted_dependency_name)
      @const_name = extracted_const_name
      @method_name = extracted_method_name&.to_sym
    end

    def receiver_method
      resolved_key = @resolved_key
      extracted_method_name = @method_name

      if extracted_method_name
        proc do |*args, **options, &block|
          Deps::CONTAINER[resolved_key].public_send(extracted_method_name, *args, **options, &block)
        end
      else
        proc do
          Deps::CONTAINER[resolved_key]
        end
      end
    end

    def const_get
      Object.const_get(@const_name) if @const_name
    end

  end
end

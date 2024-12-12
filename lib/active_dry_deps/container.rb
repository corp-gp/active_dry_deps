# frozen_string_literal: true

module ActiveDryDeps
  class Container < Hash

    def resolve(container_key)
      unless key?(container_key)
        self[container_key] = Entry.new(value: Object.const_get(container_key))
      end

      self[container_key]&.value
    end

    def register(container_key, &block)
      self[container_key.to_s] = Entry.new(proc: block)
    end

    Entry =
      Struct.new(:input) do
        def initialize(input = {})
          super
          @value = input[:value] if input.key?(:value)
        end

        def value
          return @value if defined? @value

          @value = input.fetch(:proc).call
        end
      end

  end
end

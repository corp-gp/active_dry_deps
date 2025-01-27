# frozen_string_literal: true

module ActiveDryDeps
  class Container < Hash

    def resolve_internal(container_key)
      value = self[container_key]
      value.is_a?(Proc) ? value.call : value
    end

    def register(container_key, value = nil)
      unless container_key.is_a?(String)
        raise ArgumentError, "+#{container_key}+ must be a String"
      end

      self[container_key] = block_given? ? yield : value
    end

  end
end

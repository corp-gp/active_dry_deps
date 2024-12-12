# frozen_string_literal: true

module ActiveDryDeps
  class Container < Hash

    def resolve(container_key)
      value = self[container_key]
      value.is_a?(Proc) ? value.call : value
    end

    def register(container_key, value = nil)
      self[container_key.to_s] = block_given? ? yield : value
    end

  end
end

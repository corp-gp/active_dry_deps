# frozen_string_literal: true

module ActiveDryDeps
  module StubDeps
    def stub(key, value)
      self::CONTAINER.stub(key, value)
    end

    def unstub(*keys)
      self::CONTAINER.unstub(*keys, container: ORIGINAL_WITH_GLOBAL)
    end

    def global_stub(key, value)
      ORIGINAL_WITH_GLOBAL[key] = value
      self::CONTAINER.stub(key, value)
    end

    def global_unstub(*keys)
      self::CONTAINER.unstub(*keys, container: ORIGINAL)
    end
  end

  module StubContainer
    def stub(key, value)
      self[key] = value
    end

    def unstub(*unstub_keys, container:)
      if unstub_keys.empty?
        replace(container)
      else
        unstub_keys.each do |key|
          if container.key?(key)
            self[key] = container[key]
          else
            delete(key)
          end
        end
      end
    end
  end

  module Deps
    def self.enable_stubs!
      StubDeps.const_set(:ORIGINAL, Deps::CONTAINER.dup)
      StubDeps.const_set(:ORIGINAL_WITH_GLOBAL, Deps::CONTAINER.dup)

      Deps::CONTAINER.extend(StubContainer)
      Deps.extend StubDeps
    end
  end
end

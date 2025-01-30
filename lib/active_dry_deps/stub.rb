# frozen_string_literal: true

module ActiveDryDeps

  module StubDeps

    def stub(key, value)
      self::CONTAINER.stub(key, value)
    end

    def unstub(*keys)
      self::CONTAINER.unstub(*keys)
    end

    def shared_stub(key, value)
      self::CONTAINER.stub(key, value, shared: true)
    end

    def shared_unstub(*keys)
      self::CONTAINER.unstub(*keys, shared: true)
    end

  end

  module StubContainer

    def self.extended(container)
      const_set(:CONTAINER_ORIG, container.dup)
      const_set(:SHARED_STUBS, {})
    end

    def stub(key, value, shared: false)
      SHARED_STUBS[key] = value if shared

      self[key] = value
    end

    def unstub(*unstub_keys, shared: false)
      unstubbed_container =
        if shared
          CONTAINER_ORIG
        else
          CONTAINER_ORIG.merge(SHARED_STUBS)
        end
      if unstub_keys.empty?
        replace(unstubbed_container)
      else
        unstub_keys.each do |key|
          if unstubbed_container.key?(key)
            self[key] = unstubbed_container[key]
          else
            delete(key)
          end
        end
      end
    end

  end

  module Deps

    def self.enable_stubs!
      Deps::CONTAINER.extend(StubContainer)
      Deps.extend StubDeps
    end

  end

end

# frozen_string_literal: true

module ActiveDryDeps

  module StubDeps

    def stub(key, value)
      self::CONTAINER.stub(key, value)
    end

    def unstub(*keys)
      self::CONTAINER.unstub(*keys)
    end

  end

  module StubContainer

    def self.extended(container)
      const_set(:CONTAINER_ORIG, container.dup)
    end

    def stub(key, value)
      self[key] = value
    end

    def unstub(*unstub_keys)
      if unstub_keys.empty?
        replace(CONTAINER_ORIG)
      else
        unstub_keys.each do |key|
          if CONTAINER_ORIG.key?(key)
            self[key] = CONTAINER_ORIG[key]
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

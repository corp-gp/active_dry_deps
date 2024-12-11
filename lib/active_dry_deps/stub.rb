# frozen_string_literal: true

module ActiveDryDeps

  module StubDeps

    def stub(key, proxy_object, &block)
      self::CONTAINER.stub(key, proxy_object, &block)
    end

    def unstub(*keys)
      self::CONTAINER.unstub(*keys)
    end

  end

  module StubContainer

    def self.extended(container)
      const_set(:CONTAINER_ORIG, container.dup)
    end

    def stub(key, proxy_object)
      if block_given?
        begin
          self[key] = proxy_object
        ensure
          unstub(key)
        end
      else
        self[key] = proxy_object
      end
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

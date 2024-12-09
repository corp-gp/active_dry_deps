# frozen_string_literal: true

module ActiveDryDeps

  module StubDeps

    def stub(const_name, proxy_object, &block)
      self::CONTAINER.stub(const_name, proxy_object, &block)
    end

    def unstub(*keys)
      self::CONTAINER.unstub(*keys)
    end

  end

  module StubContainer

    def stub(const_name, proxy_object)
      if block_given?
        begin
          self[const_name] = proxy_object
        ensure
          delete(const_name)
        end
      else
        self[const_name] = proxy_object
      end
    end

    def unstub(*unstub_keys)
      (unstub_keys.empty? ? keys : unstub_keys).each { |const_name| delete(const_name) }
    end

  end

  module Deps

    def self.enable_stubs!
      Deps::CONTAINER.extend(StubContainer)
      Deps.extend StubDeps
    end

  end

end

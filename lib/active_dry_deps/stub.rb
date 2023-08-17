# frozen_string_literal: true

module ActiveDryDeps

  module Stub

    CONTAINER_CONST = Object.const_get(ActiveDryDeps.config.container)

    def stub(path, ...)
      CONTAINER_CONST.stub(Deps.resolve_key(path), ...)
    end

    def unstub(*keys)
      CONTAINER_CONST.unstub(*keys.map { resolve_key(_1) })
    end

  end

  module Deps

    def self.enable_stubs!
      extend Stub
    end

  end

end

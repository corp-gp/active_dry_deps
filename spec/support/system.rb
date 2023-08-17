# frozen_string_literal: true

LOADER =
  Class.new(Dry::System::Loader) do
    def self.call(component, *args)
      constant = self.constant(component)

      if singleton?(constant)
        constant.instance(*args)
      else
        constant # constant.new(*args) - THIS LINE REWRITED from Dry::System::Loader
      end
    end
  end

require 'dry/system/container'
module Combustion
  class Container < Dry::System::Container

    configure do |config|
      config.root = Pathname('./spec')
      config.component_dirs.add 'app' do |dir|
        dir.loader = LOADER
      end
    end

  end
end

require 'dry/core/container/stub'
Combustion::Container.enable_stubs!

require 'active_dry_deps/stub'
Deps.enable_stubs!

Combustion::Container.finalize!(freeze: false)

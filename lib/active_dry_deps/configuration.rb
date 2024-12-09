# frozen_string_literal: true

require 'dry-configurable'

module ActiveDryDeps

  extend Dry::Configurable

  setting :inflector, default: ActiveSupport::Inflector
  setting :inject_global_constant, default: 'Deps'

end

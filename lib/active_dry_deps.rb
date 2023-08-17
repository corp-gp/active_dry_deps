# frozen_string_literal: true

require_relative 'active_dry_deps/version'
require_relative 'active_dry_deps/configuration'
require_relative 'active_dry_deps/railtie'

module ActiveDryDeps

  class Error < StandardError; end
  class DependencyNameInvalid < Error; end

end

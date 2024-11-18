# frozen_string_literal: true

require 'active_dry_deps/version'
require 'active_dry_deps/configuration'
require 'active_dry_deps/railtie'

module ActiveDryDeps

  autoload :Deps, 'active_dry_deps/deps'

  class Error < StandardError; end
  class DependencyNameInvalid < Error; end

end

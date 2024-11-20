# frozen_string_literal: true

require 'active_support'
require 'rails'

require 'bundler'
Bundler.require :default

$DEPENDENCY_MAP = ActiveDryDeps::DependencyMap.new
$DEPENDENCY_BY_NAME = {}

Rails.application.initialize!

Deps.subscribe(:included_dependency) do |event|
  $DEPENDENCY_MAP.register(event[:receiver], event[:dependencies].map(&:name))
  event[:dependencies].each { $DEPENDENCY_BY_NAME[_1.name] = _1 }
end

Dir['./spec/app/**/*.rb'].each { |f| require f }
Dir['./spec/support/*.rb'].each { |f| require f }

require 'active_dry_deps/rspec'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

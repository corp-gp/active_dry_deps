# frozen_string_literal: true

require "active_support"
require "rails"

require "bundler"
Bundler.require :default

Rails.application.initialize!

class Mailer

  def call(message)
    "email-sent-#{message}"
  end

end

class PushService

  def self.call = "original-push"

end

Deps.register("stats", Class.new { def self.track = "track" })
Deps.register("tick", -> { rand })
Deps.register("mailer") { Mailer.new }

Dir["./spec/app/**/*.rb"].each { |f| require f }
Dir["./spec/support/*.rb"].each { |f| require f }

require "active_dry_deps/rspec"

Deps.global_stub("PushService", Class.new { def self.call = "global-stub-push" })

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

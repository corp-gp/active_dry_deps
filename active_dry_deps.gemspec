# frozen_string_literal: true

require_relative "lib/active_dry_deps/version"

Gem::Specification.new do |spec|
  spec.name = "active_dry_deps"
  spec.version = ActiveDryDeps::VERSION
  spec.authors = ["Ermolaev Andrey"]
  spec.email = ["andruhafirst@yandex.ru"]

  spec.summary = "Dependency injection and resolution support for classes and modules."
  spec.description = <<~DESCRIPTION
    ActiveDryDeps does not modify constructor and supports Dependency Injection for modules.
    Also you can import method from any object in your container.
    Adding extra dependencies is easy and improve readability your code.
  DESCRIPTION
  spec.homepage = "https://github.com/corp-gp/active_dry_deps"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/corp-gp/active_dry_deps"
  spec.metadata["changelog_uri"] = "https://github.com/corp-gp/active_dry_deps/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files =
    Dir.chdir(__dir__) do
      `git ls-files -z`.split("\x0").reject do |f|
        (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
      end
    end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "dry-configurable"
  spec.add_dependency "dry-monitor"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata["rubygems_mfa_required"] = "true"
end

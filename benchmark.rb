# frozen_string_literal: true

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'benchmark-ips', require: 'benchmark/ips'
  gem 'kalibera'
  gem 'rails'
  gem 'dry-container'
  gem 'dry-system'
  gem 'active_dry_deps', path: '.'
end

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
class Container < Dry::System::Container; end

PROVIDERS = 10.times.to_a.map { "provider#{_1}" }

PROVIDERS.each_with_index do |provider, idx|
  Container.register_provider(provider) do
    start { register(provider.to_sym, idx) }
  end
end

Container.finalize!
p Container.keys

ActiveDryDeps.config.container = 'Container'

module ActiveDryDeps
  module CurrentDeps

    VALID_NAME = /([a-zA-Z_0-9]*)$/
    METHODS_AS_KLASS = %w[perform_later call].freeze

    module_function

    # include Deps[routes_admin: 'Lib::Routes.admin'] use as `routes_admin`
    # include Deps['Lib::Routes.admin'] use as `admin`
    # include Deps['Lib::Routes'] use as `Routes()`
    # include Deps['OrderService::Recalculate.call'] use as `Recalculate()`
    def [](*keys, **aliases)
      str_methods = +''

      keys.each { |resolver| str_methods << str_method(resolver, nil) }
      aliases.each { |alias_method, resolver| str_methods << str_method(resolver, alias_method) }

      m = Module.new
      m.module_eval(str_methods)
      m
    end

    private def str_method(resolve, alias_method)
      resolve_klass, extract_method = resolve.split('.')

      alias_method ||=
        if extract_method && METHODS_AS_KLASS.exclude?(extract_method)
          extract_method
        else
          resolve_klass.split('::').last
        end

      if alias_method && !VALID_NAME.match?(alias_method.to_s)
        raise DependencyNameInvalid, "name +#{alias_method}+ is not a valid Ruby identifier"
      end

      key = resolve_key(resolve_klass)

      if extract_method
        %(def #{alias_method}(...); ::#{ActiveDryDeps.config.container}['#{key}'].#{extract_method}(...) end\n)
      else
        %(def #{alias_method}; ::#{ActiveDryDeps.config.container}['#{key}'] end\n)
      end
    end

    def resolve_key(key)
      ActiveDryDeps.config.inflector.underscore(key).tr('/', '.')
    end

    instance_eval <<~RUBY, __FILE__, __LINE__ + 1
      # def resolve(key)
      #   ::MyApp::Container[resolve_key(key)]
      # end

      def resolve(key)
        ::#{ActiveDryDeps.config.container}[resolve_key(key)]
      end
    RUBY

  end
end

test_current = Class.new.include(ActiveDryDeps::CurrentDeps[*PROVIDERS]).new
test_new = Class.new.include(ActiveDryDeps::Deps[*PROVIDERS]).new
puts PROVIDERS.all? { test_current.public_send(_1) == test_new.public_send(_1) }

CASES_COUNT = 2_000_000
test_case_current = Array.new(CASES_COUNT) { Class.new }
test_case_new = Array.new(CASES_COUNT) { Class.new }

puts "\nBenchmark multiple include with multiple providers"
Benchmark.ips do |x|
  x.warmup = 0
  x.report('current') do
    test_case_current.shift.include(ActiveDryDeps::CurrentDeps[*PROVIDERS])
  end
  x.report('new') do
    test_case_new.shift.include(ActiveDryDeps::Deps[*PROVIDERS])
  end
  x.compare!
end

# TestClassCurrent = Class.new
# TestClassNew = Class.new
#
# puts "\nBenchmark single include"
# Benchmark.ips do |x|
#   x.warmup = 0
#   x.report("current") do
#     TestClassCurrent.include(ActiveDryDeps::CurrentDeps[*PROVIDERS])
#   end
#   x.report("new") do
#     TestClassNew.include(ActiveDryDeps::Deps[*PROVIDERS])
#   end
#   x.compare!
# end; 1

# puts "\nBenchmark class with include"
# Benchmark.ips do |x|
#   x.warmup = 0
#   x.report("current") do
#     Class.new { include ActiveDryDeps::CurrentDeps[*PROVIDERS] }
#   end
#   x.report("new") do
#     Class.new { include ActiveDryDeps::Deps[*PROVIDERS] }
#   end
#   x.compare!
# end; 1

test_case_current = Class.new { include(ActiveDryDeps::CurrentDeps[*PROVIDERS]) }.new
test_case_new = Class.new { include(ActiveDryDeps::Deps[*PROVIDERS]) }.new

puts "\nBenchmark provider"
Benchmark.ips do |x|
  x.warmup = 0
  x.report('current') do
    PROVIDERS.each { test_case_current.public_send(_1) }
  end
  x.report('new') do
    PROVIDERS.each { test_case_new.public_send(_1) }
  end
  x.compare!
end; 1

# m1 = Module.new
# m2 = Module.new
#
# def inner_module_eval(i)
#   i
# end
#
# def test_module_eval(m, count)
#   str_methods = count.times.to_a { |i| "def t#{i} = inner_module_eval(#{i})" }
#   m.module_eval(str_methods.join("\n"))
# end
#
# def inner_define_method
#   proc do |i|
#     i
#   end
# end
#
# def test_define_method(m, count)
#   count.times do |i|
#     m.define_singleton_method("t#{i}", &inner_define_method)
#   end
# end
#
# [3, 10, 20, 50].each do |count|
#   puts "\nBenchmark eval vs definer: #{count} methods"
#
#   Benchmark.ips do |x|
#     x.warmup = 0
#     x.report("module_eval") { test_module_eval(m1, count) }
#     x.report("define_method") { test_define_method(m2, count) }
#     x.compare!
#   end;1
# end; 1

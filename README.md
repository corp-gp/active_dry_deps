## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add active_dry_deps

## Dependency Injection

Dependency injection helps to break explicit dependencies between objects making
it much easier to maintain a [single
responsibility](https://en.wikipedia.org/wiki/Single_responsibility_principle)
and reduce [coupling](https://en.wikipedia.org/wiki/Coupling_(computer_programming))
in our class designs. This leads to more testable code and code that is more
resilient to change.

For a deeper background on Dependency Injection consider the
[Wikipedia](https://en.wikipedia.org/wiki/Dependency_injection) article on the
subject.

## Usage

### Basic
Under the hood `active_dry_deps` uses a container like [dry-container](https://dry-rb.org/gems/dry-container) and convert key to underscore for fetch from container.
For auto-registration dependencies use [dry-system](https://dry-rb.org/gems/dry-system/).

```ruby
MyApp::Container.register('warehouse.create_departure_service', Class.new { def self.call = 'failure' })
include Deps['Warehouse::CreateDepartureService.call']
```

`Deps['Warehouse::CreateDepartureService.call']` this notation is familiar to Ruby developers, helps to find code in the project, and simplifies the migration from constants in code to defining dependencies.

```ruby
class CreateOrderService < ServiceObject

  include Deps[
    'Warehouse::CreateDepartureService.call',
    'Warehouse::ReserveJob.perform_later',
    'OrderMailer',
    'redis',
    track: 'StatsApi.message',
  ]

  def call(params)
    order = Order.create(params)

    ReserveJob(order)
    track(order.id, order.created_at)

    redis.with do |conn|
      conn.incr('order_count')
    end

    OrderMailer().with(user: user).deliver_later

    CreateDepartureService(order.slice(:id, :departure_at))
  end

end
```

```ruby
describe 'CreateOrderService' do
  it 'success create order' do
    service = described_class.new(user: create(:user), zip_code: 67_345)
    expect(service).to deps(CreateDepartureService: double(success?: true), ReserveJob: spy, track: spy)

    expect(service.call.success?).to be true
  end
end

```

### Import methods
You can inject any method from object in your container

```ruby
MyApp::Container.register(:str, 'str')
MyApp::Container.register(:service, Module.new { def self.success? = true } )

include Deps['str.reverse', 'service.success?']
reverse # => "rts"
success? # => true
```

### Import callable methods
By default, when `call` or `perform_later` methods are imported, the name of the dependency is taken from the name of the constant:
```ruby
  include Deps[
    'Warehouse::CreateDepartureService.call', # callable
    'Warehouse::ReserveJob.perform_later', # callable
    'Warehouse::ReserveJob.perform_now',
    'Warehouse::ProductActivateQuery',
  ]

  # use as
  CreateDepartureService()
  ReserveJob()
  perform_now
  ProductActivateQuery().run
```

Recommends using prefixes (`Service`, `Job`, `Query`) in the name of the constant for easy reading of the dependency type.

### Aliases

```ruby
include Deps[string: 'str.reverse', m: 'module']
string # => "rts"
m # => "success"
```

### Tests (Rspec)
#### deps
gem adds rspec matcher for stub dependency, put `require 'active_dry_deps/rspec'` to rspec setup

```ruby
GpApp::Container.register('order.dependency', Class.new { def self.call = 'failure' })

let(:service_klass) do
  Class.new do
    include Deps['Order::Dependency.call']

    def call = Dependency()
  end
end

it 'failure' do
  expect(service_klass.new.call).to be 'failure'
end

it 'success' do
  service = service_klass.new
  expect(service).to deps(Dependency: 'success')

  expect(service.call).to be 'success'
end
```

#### stub, unstub
```ruby
it 'stub' do
  Deps.stub('Order::Dependency', double(call: 'success'))
  expect(service_klass.new.call).to be 'success'

  Deps.unstub('Order::Dependency') # or simple Deps.unstub for unsub all keys
  expect(service_klass.new.call).to be 'failure'
end
```
## Configuration
gem auto-configuring, but you can override settings

```ruby
ActiveDryDeps.config.container = 'MyApp::Container'
ActiveDryDeps.config.inflector = ActiveSupport::Inflector
ActiveDryDeps.config.inject_global_constant = 'Deps'
```

### Recommended container setup with [dry-system](https://dry-rb.org/gems/dry-system/) for Rails

`config/initializers/system.rb`

```ruby
require 'dry/system/container'

module GpApp
  class ContainerRailtie < Rails::Railtie

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

    # https://api.rubyonrails.org/classes/Rails/Railtie.html
    # Add a to_prepare block which is executed once in production
    # and before each request in development.
    config.to_prepare do
      ContainerRailtie.finalize
    end

    def finalize
      container = create_container
      set_or_reload(:Container, container)
      if (providers_path = Pathname(__dir__).join("../system/providers")).exist?
        Dry::System.register_provider_sources(providers_path.realpath)
      end
      container.finalize!(freeze: !Rails.env.local?)
    end

    def create_container
      Class.new(Dry::System::Container) do
        configure do |config|
          config.inflector = ActiveSupport::Inflector
          config.root = Rails.root.join('app')

          %w[domains jobs queries services mailers].each do |dir_name|
            config.component_dirs.add dir_name do |dir|
              dir.loader = LOADER
              dir.memoize = true
            end
          end

          config.component_dirs.add '../lib' do |dir|
            dir.loader = LOADER
            dir.memoize = true
          end
        end
      end
    end

    def set_or_reload(const_name, const)
      remove_constant(const_name)
      GpApp.const_set(const_name, const)
    end

    def remove_constant(const_name)
      if GpApp.const_defined?(const_name, false)
        GpApp.__send__(:remove_const, const_name)
      end
    end

  end
end

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/corp-gp/active_dry_deps.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

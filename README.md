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
Dependencies are injected by listing their names: `Deps['Warehouse::CreateDepartureService.call']`. This notation is familiar to Ruby developers. It helps to find code in the project (compares to abstract container keys), and simplifies the migration from constants in code to defining dependencies

```ruby
class CreateOrderService
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

Rspec matcher `deps` allows to isolate dependencies in tests. It simplifies unit testing

```ruby
Rspec.describe CreateOrderService do
  it 'success create order' do
    service = described_class.new(user: create(:user), zip_code: 67_345)
    expect(service).to deps(CreateDepartureService: double(success?: true), ReserveJob: spy, track: spy)

    expect(service.call.success?).to be true
  end
end

```

#### Register custom dependency
You can define an arbitrary object as a dependency with method `Deps.register`

```ruby
class OrderMailer
  def send_mail = 'email sent'
end

Deps.register('mailer') { OrderMailer.new }

class CreateOrderService
  include Deps['mailer']

  def call
    mailer.send_mail
  end
end

CreateOrderService.new.call # => email sent
```

### Import methods
You can inject any method from constant as dependency

```ruby
class OrderRepository
  def self.overdue_order_ids = [1, 2, 3]
end

include Deps['OrderRepository.overdue_order_ids']

overdue_order_ids # => [1, 2, 3]
```

### Import callable methods
There is a special convention for naming some methods. By default, when `call` or `perform_later` methods are imported, the name of the dependency is taken from the name of the constant, not by method name

```ruby
include Deps[
  'Warehouse::CreateDepartureService.call', # callable
  'Warehouse::ReserveJob.perform_later', # callable
  'Warehouse::ReserveJob.perform_now',
  'Warehouse::ProductActivateQuery',
]

# use as
CreateDepartureService() # Warehouse::CreateDepartureService.call
ReserveJob() # Warehouse::ReserveJob.perform_later
perform_now # Warehouse::ReserveJob.perform_now
ProductActivateQuery().run # Warehouse::ProductActivateQuery.run
```

Recommends using suffixes (`Service`, `Job`, `Query`) in the name of the constant for easy reading of the dependency type.

### Aliases
Dependency can have an alias for more intuitive access. Keep in mind that dependencies with aliases should go at the end of the list (this is Ruby feature)

```ruby
include Deps['OrderMailer', product_repo: 'Warehouse::ProductRepository']

product_repo # Warehouse::ProductRepository
OrderMailer() # OrderMailer
```

### Tests (Rspec)

#### setup
For dependency testing, add the following to Rspec setup

# spec/rails_helper.rb
```ruby
# ...
require 'active_dry_deps/rspec'
require 'active_dry_deps/stub'

Deps.enable_stubs!

RSpec.configure do |config|
  config.after(:each) { Deps.unstub }
end
```

#### deps
The gem adds Rspec matcher `deps` for stub dependency

```ruby
Deps.register('order.dependency', Class.new { def self.call = 'failure' })

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
Dependency can be stubbed at the container level. This allows to override all calls to it

```ruby
it 'stub' do
  Deps.stub('Order::Dependency', double(call: 'success'))
  expect(service_klass.new.call).to be 'success'

  Deps.unstub('Order::Dependency') # or Deps.unstub() for unsub all keys
  expect(service_klass.new.call).to be 'failure'
end
```

#### global_stub, global_unstub
Sometimes it is necessary to stub dependencies for all or almost all tests

# spec/rails_helper.rb
```ruby
# ...
Deps.enable_stubs!

Deps.global_stub('PushService', Class.new { def self.call = 'webpush' })
```

Dependency stubbed with `global_stub` may be restored only with `shared_unstub`. You can unstub dependency when it really needed and ignore in all other cases 

```ruby
it 'sends webpush' do
  Deps.shared_unstub('PushService')
  
  # expect(PushService.call).to ...
end
```

*`Deps.global_stub` should not be used within examples*

## Configuration
The gem is auto-configuring, but you can override settings

```ruby
# config/initializers/active_dry_deps.rb
ActiveDryDeps.configure do |config|
  config.inflector = ActiveSupport::Inflector
  config.inject_global_constant = 'Deps'
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/corp-gp/active_dry_deps.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

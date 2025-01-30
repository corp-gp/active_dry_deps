# frozen_string_literal: true

RSpec.describe ActiveDryDeps do
  it 'all dependencies works' do
    expect(CreateOrder.call).to eq %w[CreateDeparture CreateDeparture job-performed message-ok email-sent-hello track push]
  end

  it 'stub dependencies with `deps`' do
    service = CreateOrder.new

    expect(service).to deps(
      CreateDepartureCallable: '1',
      CreateDeparture:         double(call: '2'),
      ReserveJob:              '3',
      message:                 '4',
      mailer:                  double(call: '5'),
      track:                   '6',
      PushService:             double(call: '7'),
    )
    expect(service.call).to eq %w[1 2 3 4 5 6 7]
  end

  it 'resolves block in runtime' do
    service = CreateOrder.new

    first_tick = service.tick
    second_tick = service.tick

    expect(second_tick).not_to eq(first_tick)
  end

  it 'stub dependency with `deps` not runnable' do
    service = CreateOrder.new

    expect(service).not_to deps(:message)
    service.call(is_message: false)
  end

  it 'invalid method identifier not allowed' do
    expect {
      Class.new { include Deps['CreateOrder.!invalid_identifier'] }
    }.to raise_error(ActiveDryDeps::DependencyNameInvalid, 'name +!invalid_identifier+ is not a valid Ruby identifier')
  end

  context 'when dependency missing' do
    it 'fails when const not defined' do
      expect {
        service = Class.new { include Deps['UndefinedConst'] }
        service.new.UndefinedConst()
      }.to raise_error(NameError, /uninitialized constant.*UndefinedConst/)
    end

    it 'fails when dependency not registered' do
      expect {
        service = Class.new { include Deps['unknown_method'] }
        service.new.unknown_method
      }.to raise_error(ActiveDryDeps::DependencyNotRegistered, /.+unknown_method.+not registered/)
    end

    it 'fails when method not defined' do
      expect {
        service = Class.new { include Deps['CreateOrder.unknown_method'] }
        service.new.unknown_method
      }.to raise_error(NoMethodError, /undefined method `unknown_method' for CreateOrder/)
    end
  end

  describe '#register' do
    it 'checks the container key' do
      expect {
        Deps.register(:mock, 1)
      }.to raise_error(ArgumentError, '+mock+ must be a String')
    end
  end

  describe '#stub' do
    it 'stubs dependency' do
      Deps.stub('CreateDeparture', double(call: '1'))
      Deps.stub('PushService', double(call: '2'))

      expect(CreateOrder.call).to eq %w[1 1 job-performed message-ok email-sent-hello track 2]
    end

    it 'stubs dependency with nil' do
      Deps.stub('tick', nil)

      service = CreateOrder.new

      expect(service.tick).to be_nil
    end

    it 'raises exception when calls a stub block' do
      expect {
        Deps.stub('CreateDeparture', -> { raise StandardError, 'Something went wrong' })
      }.not_to raise_error

      expect { CreateOrder.call }
        .to raise_error(StandardError, 'Something went wrong')
    end
  end

  describe '#unstub' do
    it 'unstub dependency' do
      Deps.stub('CreateDeparture', double(call: '!'))
      Deps.unstub

      expect(CreateOrder.call).to eq %w[CreateDeparture CreateDeparture job-performed message-ok email-sent-hello track push]
    end

    it 'unstub shared' do
      Deps.shared_unstub

      expect(CreateOrder.call).to eq %w[CreateDeparture CreateDeparture job-performed message-ok email-sent-hello track original-push]
    end
  end
end

# frozen_string_literal: true

RSpec.describe ActiveDryDeps do
  it 'all dependencies works' do
    expect(CreateOrder.call).to eq %w[CreateDeparture CreateDeparture job-performed message-ok email-sent-hello]
  end

  it 'stub dependencies with `deps`' do
    service = CreateOrder.new

    expect(service).to deps(
      CreateDepartureCallable: '1',
      CreateDeparture:         double(call: '2'),
      ReserveJob:              '3',
      message:                 '4',
      mailer:                  double(call: '5'),
    )
    expect(service.call).to eq %w[1 2 3 4 5]
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

  describe '#stub' do
    def expect_call_orig
      expect(CreateOrder.call).to eq %w[CreateDeparture CreateDeparture job-performed message-ok email-sent-hello]
    end

    it 'direct stub with `Deps.stub`' do
      Deps.stub('CreateDeparture', double(call: '1'))

      expect(CreateOrder.call).to eq %w[1 1 job-performed message-ok email-sent-hello]

      Deps.unstub

      expect_call_orig
    end

    it 'direct stub with `Deps.sub` with block' do
      Deps.stub('CreateDeparture', double(call: '1')) do
        expect(CreateOrder.call).to eq %w[1 1 job-performed message-ok email-sent-hello]
      end

      expect_call_orig
    end
  end
end

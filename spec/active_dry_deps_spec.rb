# frozen_string_literal: true

RSpec.describe ActiveDryDeps do
  it 'all dependencies works' do
    expect(CreateOrder.call).to eq %w[CreateDeparture CreateDeparture perform_later message-ok]
  end

  it 'dependencies resolved' do
    expect(Deps.resolve('CreateDeparture')).to eq CreateDeparture
    expect(Deps.resolve('SupplierSync::ReserveJob')).to eq SupplierSync::ReserveJob
    expect(Deps.resolve('supplier_sync.reserve_job')).to eq SupplierSync::ReserveJob
  end

  it 'stub dependencies with `deps`' do
    service = CreateOrder.new

    expect(service).to deps(CreateDepartureCallable: '1', CreateDeparture: double(call: '2'), ReserveJob: '3', message: '4')
    expect(service.call).to eq %w[1 2 3 4]
  end

  it 'stub dependency with `deps` not runnable' do
    service = CreateOrder.new

    expect(service).not_to deps(:message)
    service.call(is_message: false)
  end

  it 'direct stub with `Deps.sub`' do
    Deps.stub('create_departure', double(call: '1'))

    expect(CreateOrder.call).to eq %w[1 1 perform_later message-ok]

    Deps.unstub
  end

  it 'direct stub with `Deps.sub` with block' do
    Deps.stub('create_departure', double(call: '1')) do
      expect(CreateOrder.call).to eq %w[1 1 perform_later message-ok]
    end
  end
end

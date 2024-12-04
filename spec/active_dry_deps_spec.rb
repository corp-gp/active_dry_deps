# frozen_string_literal: true

RSpec.describe ActiveDryDeps do
  it 'all dependencies works' do
    expect(CreateOrder.call).to eq %w[CreateDeparture CreateDeparture perform_later message-ok email-sent]
  end

  it 'dependencies resolved' do
    expect(Deps.resolve('CreateDeparture')).to eq CreateDeparture
    expect(Deps.resolve('SupplierSync::ReserveJob')).to eq SupplierSync::ReserveJob
    expect(Deps.resolve('supplier_sync.reserve_job')).to eq SupplierSync::ReserveJob
  end

  it 'dot notation not allowed' do
    expect {
      Class.new do
        include Deps['a.b']
      end
    }.to raise_error(ActiveDryDeps::DependencyNameInvalid, "+a.b+ must contains a class/module name. Make sure not use dot-notation 'a.b.c'")
  end

  it 'invalid method identifier not allowed' do
    expect {
      Class.new do
        include Deps['CreateOrder.!invalid_identifier']
      end
    }.to raise_error(ActiveDryDeps::DependencyNameInvalid, 'name +!invalid_identifier+ is not a valid Ruby identifier')
  end

  it 'stub dependencies with `deps`' do
    service = CreateOrder.new

    expect(service).to deps(
      CreateDepartureCallable: '1',
      CreateDeparture:         double(call: '2'),
      ReserveJob:              '3',
      message:                 '4',
      order_mailer:            double(call: '5'),
    )
    expect(service.call).to eq %w[1 2 3 4 5]
  end

  it 'stub dependency with `deps` not runnable' do
    service = CreateOrder.new

    expect(service).not_to deps(:message)
    service.call(is_message: false)
  end

  it 'direct stub with `Deps.sub`' do
    Deps.stub('create_departure', double(call: '1'))

    expect(CreateOrder.call).to eq %w[1 1 perform_later message-ok email-sent]

    Deps.unstub
  end

  it 'direct stub with `Deps.sub` with block' do
    Deps.stub('create_departure', double(call: '1')) do
      expect(CreateOrder.call).to eq %w[1 1 perform_later message-ok email-sent]
    end
  end

  describe 'check dependencies' do
    it '#check_cyclic_references found circular dependencies' do
      expect { $DEPENDENCY_MAP.check_cyclic_references }.to raise_error(ActiveDryDeps::CircularDependency, <<~TEXT)
        Expected the dependency graph to be acyclic, but it contains the following circular dependencies:
        CreateDeparture → CreateOrder → CreateDeparture
      TEXT
    end

    it 'dependency load constant' do
      expect($DEPENDENCY_BY_NAME['CreateDeparture'].const_get).to eq CreateDeparture
    end
  end
end

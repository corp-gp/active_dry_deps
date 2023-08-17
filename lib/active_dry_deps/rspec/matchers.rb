# frozen_string_literal: true

RSpec::Matchers.define :deps do |*methods|
  include RSpec::Mocks::Matchers::Matcher

  # expect(described_instance).to deps(send_blanks: spy)
  match do |stubbed_object|
    methods[0].each do |method, returned_value|
      expect(stubbed_object).to receive(method).and_return(returned_value)
    end
  end

  # expect(described_instance).not_to deps(:send_blanks)
  match_when_negated do |stubbed_object|
    methods.each do |method|
      expect(stubbed_object).not_to receive(method)
    end
  end

  # allow(described_instance).to deps(send_blanks: spy)
  def setup_allowance(subject)
    proxy_subject = proxy_on(subject)

    expected.each do |method, returned_value|
      proxy_on(returned_value).add_simple_stub(:call, returned_value.call)
      proxy_subject.add_simple_stub(method, returned_value)
    end
  end

  private def proxy_on(subject)
    RSpec::Mocks.space.proxy_for(subject)
  end
end

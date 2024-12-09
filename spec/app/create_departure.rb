# frozen_string_literal: true

class CreateDeparture

  include Deps['CreateOrder']

  def self.call
    "CreateDeparture"
  end

end

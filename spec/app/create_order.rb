# frozen_string_literal: true

class CreateOrder

  def self.call
    new.call
  end

  include Deps[
    'CreateDeparture',
    'Utils.message',
    'SupplierSync::ReserveJob.perform_later',
    'send_mail',
    CreateDepartureCallable: 'CreateDeparture.call',
  ]

  def call(is_message: true)
    [
      CreateDepartureCallable(),
      CreateDeparture().call,
      ReserveJob(),
      (message('ok') if is_message),
      send_mail,
    ]
  end

end

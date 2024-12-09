# frozen_string_literal: true

module ActiveDryDeps
  class Container < Hash

    def resolve(const_name)
      unless key?(const_name)
        self[const_name] = Object.const_get(const_name)
      end

      self[const_name]
    end

  end
end

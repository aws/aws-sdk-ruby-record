module Aws
  module Record
    class Attribute

      attr_reader :name

      def initialize(name, marshaler, validators = [])
        @name = name
        @marshaler = marshaler
        @validators = validators
      end

      def type_cast(raw_value)
        @marshaler.type_cast(raw_value)
      end

      def serialize(raw_value)
        @marshaler.serialize(raw_value)
      end

      def valid?(raw_value)
        value = type_cast(raw_value)
        valid = true
        @validators.each do |validator|
          if !validator.validate(value)
            valid = false
            break
          end
        end
        valid
      end

    end
  end
end

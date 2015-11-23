module Aws
  module Record
    class Attribute

      attr_reader :name

      def initialize(name, options = {})
        @name = name
        @marshaler = options[:marshaler] || DefaultMarshaler
        @validators = options[:validators] || []
      end

      def type_cast(raw_value)
        @marshaler.type_cast(raw_value)
      end

      def serialize(raw_value)
        @marshaler.serialize(raw_value)
      end

      def valid?(raw_value)
        value = type_cast(raw_value)
        @validators.all? do |validator|
          validator.validate(value)
        end
      end

    end

    module DefaultMarshaler
      def self.type_cast(raw_value, options = {})
        raw_value
      end

      def self.serialize(raw_value, options = {})
        { s: raw_value }
      end
    end
  end
end

module Aws
  module Record
    class Attribute

      attr_reader :name, :database_name, :dynamodb_type

      # @param [Symbol] name Name of the attribute. It should be a name that is
      #  safe to use as a method.
      # @param [Hash] options
      # @option options [Marshaler] :marshaler The marshaler for this attribute.
      #   So long as you provide a marshaler which implements `#type_cast` and
      #   `#serialize` that consume raw values as expected, you can bring your
      #   own marshaler type.
      # @option options [Array] :validators An array of validator classes that
      #   will be run when an attribute is checked for validity.
      # @option options [String] :database_attribute_name Optional attribute
      #   used to specify a different name for database persistence than the
      #   `name` parameter. Must be unique (you can't have overlap between
      #   database attribute names and the names of other attributes).
      # @option options [String] :dynamodb_type Generally used for keys and
      #   index attributes, one of "S", "N", "B", "BOOL", "SS", "NS", "BS",
      #   "M", "L". Optional if this attribute will never be used for a key or
      #   secondary index, but most convenience methods for setting attributes
      #   will provide this.
      def initialize(name, options = {})
        @name = name
        @database_name = options[:database_attribute_name] || name.to_s
        @dynamodb_type = options[:dynamodb_type]
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

      def extract(dynamodb_item)
        dynamodb_item[database_name]
      end

    end

    module DefaultMarshaler
      def self.type_cast(raw_value, options = {})
        raw_value
      end

      def self.serialize(raw_value, options = {})
        raw_value
      end
    end
  end
end

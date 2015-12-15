module Aws
  module Record
    module Attributes

      def self.included(sub_class)
        sub_class.extend(ClassMethods)
        sub_class.instance_variable_set("@keys", {})
        sub_class.instance_variable_set("@attributes", {})
      end

      def initialize
        @data = {}
      end

      # Returns a hash representation of the attribute data.
      #
      # @return [Hash] Map of attribute names to raw values.
      def to_h
        @data.dup
      end

      module ClassMethods

        # Define an attribute for your model, providing your own attribute type.
        #
        # @param [Symbol] name Name of this attribute.  It should be a name that
        #   is safe to use as a method.
        # @param [Marshaler] marshaler The marshaler for this attribute. So long
        #   as you provide a marshaler which implements `#type_cast` and
        #   `#serialize` that consume raw values as expected, you can bring your
        #   own marshaler type. Convenience methods will provide this for you.
        # @param [Hash] options
        # @option options [Array] :validators An array of validator classes that
        #   will be run when an attribute is checked for validity.
        # @option options [String] :dynamodb_type Generally used for keys and
        #   index attributes, one of "S", "N", "B", "BOOL", "SS", "NS", "BS",
        #   "M", "L".
        # @option options [Boolean] :hash_key Set to true if this attribute is
        #   the hash key for the table.
        # @option options [Boolean] :range_key Set to true if this attribute is
        #   the range key for the table.
        def attr(name, marshaler, opts = {})
          raise "Must use symbolized :name attribute." unless name.is_a?(Symbol)
          attr_name = name.to_s # Can also pass as option?

          if @attributes[name]
            raise "Cannot overwrite existing attribute #{name}"
          end

          opts = opts.merge(marshaler: marshaler)
          attribute = Attribute.new(attr_name, opts)
          @attributes[name] = attribute

          define_method(attr_name) do
            raw = @data[name]
            attribute.type_cast(raw)
          end

          define_method("#{attr_name}=") do |value|
            @data[name] = value
          end

          key_attributes(name, opts)
        end

        # Define a string-type attribute for your model.
        #
        # @param [Symbol] name Name of this attribute.  It should be a name that
        #   is safe to use as a method.
        # @param [Hash] options
        # @option options [Boolean] :hash_key Set to true if this attribute is
        #   the hash key for the table.
        # @option options [Boolean] :range_key Set to true if this attribute is
        #   the range key for the table.
        def string_attr(id, opts = {})
          opts[:dynamodb_type] = "S"
          attr(id, Attributes::StringMarshaler, opts)
        end

        # Define a boolean-type attribute for your model.
        #
        # @param [Symbol] name Name of this attribute.  It should be a name that
        #   is safe to use as a method.
        # @param [Hash] options
        # @option options [Boolean] :hash_key Set to true if this attribute is
        #   the hash key for the table.
        # @option options [Boolean] :range_key Set to true if this attribute is
        #   the range key for the table.
        def boolean_attr(id, opts = {})
          opts[:dynamodb_type] = "BOOL"
          attr(id, Attributes::BooleanMarshaler, opts)
        end

        # Define a integer-type attribute for your model.
        #
        # @param [Symbol] name Name of this attribute.  It should be a name that
        #   is safe to use as a method.
        # @param [Hash] options
        # @option options [Boolean] :hash_key Set to true if this attribute is
        #   the hash key for the table.
        # @option options [Boolean] :range_key Set to true if this attribute is
        #   the range key for the table.
        def integer_attr(id, opts = {})
          opts[:dynamodb_type] = "N"
          attr(id, Attributes::IntegerMarshaler, opts)
        end

        # Define a float-type attribute for your model.
        #
        # @param [Symbol] name Name of this attribute.  It should be a name that
        #   is safe to use as a method.
        # @param [Hash] options
        # @option options [Boolean] :hash_key Set to true if this attribute is
        #   the hash key for the table.
        # @option options [Boolean] :range_key Set to true if this attribute is
        #   the range key for the table.
        def float_attr(id, opts = {})
          opts[:dynamodb_type] = "N"
          attr(id, Attributes::FloatMarshaler, opts)
        end

        # Define a date-type attribute for your model.
        #
        # @param [Symbol] name Name of this attribute.  It should be a name that
        #   is safe to use as a method.
        # @param [Hash] options
        # @option options [Boolean] :hash_key Set to true if this attribute is
        #   the hash key for the table.
        # @option options [Boolean] :range_key Set to true if this attribute is
        #   the range key for the table.
        def date_attr(id, opts = {})
          opts[:dynamodb_type] = "S"
          attr(id, Attributes::DateMarshaler, opts)
        end

        # Define a datetime-type attribute for your model.
        #
        # @param [Symbol] name Name of this attribute.  It should be a name that
        #   is safe to use as a method.
        # @param [Hash] options
        # @option options [Boolean] :hash_key Set to true if this attribute is
        #   the hash key for the table.
        # @option options [Boolean] :range_key Set to true if this attribute is
        #   the range key for the table.
        def datetime_attr(id, opts = {})
          opts[:dynamodb_type] = "S"
          attr(id, Attributes::DateTimeMarshaler, opts)
        end

        # @return [Hash] hash of symbolized attribute names to attribute objects
        def attributes
          @attributes
        end

        # @return [Aws::Record::Attribute,nil]
        def hash_key
          @attributes[@keys[:hash]]
        end

        # @return [Aws::Record::Attribute,nil]
        def range_key
          @attributes[@keys[:range]]
        end

        protected
        def key_attributes(id, opts)
          if opts[:hash_key] == true && opts[:range_key] == true
            raise "Cannot have the same attribute be a hash and range key."
          elsif opts[:hash_key] == true
            define_key(id, :hash)
          elsif opts[:range_key] == true
            define_key(id, :range)
          end
        end

        def define_key(id, type)
          @keys[type] = id
        end
      end

    end
  end
end

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

          validators = opts[:validators]

          attribute = Attribute.new(attr_name, marshaler, validators)
          @attributes[name] = attribute

          define_method(attr_name) do
            raw = @data[attr_name]
            attribute.type_cast(raw)
          end

          define_method("#{attr_name}=") do |value|
            @data[attr_name] = value
          end

          # In an ActiveModel support module?
          define_method("#{attr_name}_before_type_cast") do
            @data[attr_name]
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
          attr(id, BooleanAttr, opts)
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
          attr(id, IntegerAttr, opts)
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
          attr(id, FloatAttr, opts)
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
          attr(id, DateAttr, opts)
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
          attr(id, DateTimeAttr, opts)
        end

        # @return [???,nil]
        def hash_key
          @attributes[@keys[:hash]]
        end

        # @return [???,nil]
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

      # Base class for all of the Aws::Record attributes.
      class BaseAttr
      end

      class StringAttr < BaseAttr
        def self.type_cast(raw)
          raw.to_s
        end
      end

      class BooleanAttr < BaseAttr
        def self.type_cast(raw)
          case raw
          when nil then nil
          when '' then nil
          when false, 'false', '0', 0 then false
          else true
          end
        end
      end

      class IntegerAttr < BaseAttr
        def self.type_cast(raw)
          case raw
          when nil      then nil
          when ''       then nil
          when Integer  then raw
          else
            raw.respond_to?(:to_i) ?
              raw.to_i :
              raw.to_s.to_i
          end
        end
      end

      class FloatAttr < BaseAttr
        def self.type_cast(raw)
          case raw_value
          when nil   then nil
          when ''    then nil
          when Float then raw_value
          else
            raw_value.respond_to?(:to_f) ?
              raw_value.to_f :
              raw_value.to_s.to_f
          end
        end
      end

      class DateAttr < BaseAttr
        def self.type_cast(raw)
          case raw
          when nil      then nil
          when ''       then nil
          when Date     then raw
          when Integer  then
            begin
              Date.parse(Time.at(raw).to_s) # assumed timestamp
            rescue
              nil
            end
          else
            begin
              Date.parse(raw.to_s) # Time, DateTime or String
            rescue
              nil
            end
          end
        end
      end

      class DateTimeAttr < BaseAttr
        def self.type_cast(raw)
          case raw
          when nil      then nil
          when ''       then nil
          when DateTime then raw
          when Integer  then
            begin
              DateTime.parse(Time.at(raw).to_s) # timestamp
            rescue
              nil
            end
          else
            begin
              DateTime.parse(raw.to_s) # Time, Date or String
            rescue
              nil
            end
          end
        end
      end

    end
  end
end

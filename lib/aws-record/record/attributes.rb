module Aws
  module Record
    module Attributes

      def self.included(sub_class)
        sub_class.extend(ClassMethods)
        sub_class.instance_variable_set("@keys", {})
        sub_class.instance_variable_set("@attributes", {})
        sub_class.instance_variable_set("@storage_attributes", {})
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
        # @option options [String] :database_attribute_name Optional attribute
        #   used to specify a different name for database persistence than the
        #   `name` parameter. Must be unique (you can't have overlap between
        #   database attribute names and the names of other attributes).
        # @option options [String] :dynamodb_type Generally used for keys and
        #   index attributes, one of "S", "N", "B", "BOOL", "SS", "NS", "BS",
        #   "M", "L". Optional if this attribute will never be used for a key or
        #   secondary index, but most convenience methods for setting attributes
        #   will provide this.
        # @option options [Boolean] :hash_key Set to true if this attribute is
        #   the hash key for the table.
        # @option options [Boolean] :range_key Set to true if this attribute is
        #   the range key for the table.
        def attr(name, marshaler, opts = {})
          unless name.is_a?(Symbol)
            raise ArgumentError.new("Must use symbolized :name attribute.")
          end
          attr_name = name.to_s

          if @attributes[name]
            raise Errors::NameCollision.new(
              "Cannot overwrite existing attribute #{name}"
            )
          end

          opts = opts.merge(marshaler: marshaler)
          attribute = Attribute.new(name, opts)

          # Check for collisions when storage and attr names vary.
          storage_name = attribute.database_name
          if @attributes[storage_name]
            raise Errors::NameCollision.new(
              "Custom storage name #{storage_name} already exists as an"\
                " attribute name in #{@attributes}"
            )
          elsif @storage_attributes[attr_name]
            raise Errors::NameCollision.new(
              "Attribute name #{name} already exists as a custom storage"\
                " name in #{@storage_attributes}"
            )
          elsif @storage_attributes[storage_name]
            raise Errors::NameCollision.new(
              "Custom storage name #{storage_name} already in use in"\
                " #{@storage_attributes}"
            )
          end

          if instance_methods.include?(name)
            raise Errors::ReservedName.new(
              "Cannot name an attribute #{name}, that would collide with an"\
                " existing instance method."
            )
          end

          @attributes[name] = attribute
          @storage_attributes[storage_name] = name

          define_attr_methods(name, attribute)
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

        # @param [String] storage_name The attribute name as used for storage in
        #   Amazon DynamoDB.
        # @return [Symbol] The attribute name as used in the attributes hash.
        def attribute_name(storage_name)
          @storage_attributes[storage_name]
        end

        # @return [Aws::Record::Attribute,nil]
        def hash_key
          @attributes[@keys[:hash]]
        end

        # @return [Aws::Record::Attribute,nil]
        def range_key
          @attributes[@keys[:range]]
        end

        # @return [Hash] A mapping of the :hash and :range keys to the attribute
        #   name symbols associated with them.
        def keys
          @keys
        end

        protected
        def define_attr_methods(name, attribute)
          define_method(name) do
            raw = @data[name]
            attribute.type_cast(raw)
          end

          define_method("#{name}=") do |value|
            @data[name] = value
          end
        end

        def key_attributes(id, opts)
          if opts[:hash_key] == true && opts[:range_key] == true
            raise ArgumentError.new(
              "Cannot have the same attribute be a hash and range key."
            )
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

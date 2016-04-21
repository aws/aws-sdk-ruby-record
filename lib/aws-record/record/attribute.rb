# Copyright 2015-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not
# use this file except in compliance with the License. A copy of the License is
# located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is distributed on
# an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing permissions
# and limitations under the License.

module Aws
  module Record
    class Attribute

      attr_reader :name, :database_name, :dynamodb_type

      # @param [Symbol] name Name of the attribute. It should be a name that is
      #  safe to use as a method.
      # @param [Hash] options
      # @option options [Marshaler] :marshaler The marshaler for this attribute.
      #   So long as you provide a marshaler which implements +#type_cast+ and
      #   +#serialize+ that consume raw values as expected, you can bring your
      #   own marshaler type.
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
      end

      # Attempts to type cast a raw value into the attribute's type. This call
      # will forward the raw value to this attribute's marshaler class.
      #
      # @return [Object] the type cast object. Return type is dependent on the
      #  marshaler used. See your attribute's marshaler class for details.
      def type_cast(raw_value)
        @marshaler.type_cast(raw_value)
      end

      # Attempts to serialize a raw value into the attribute's serialized
      # storage type. This call will forward the raw value to this attribute's
      # marshaler class.
      #
      # @return [Object] the serialized object. Return type is dependent on the
      #  marshaler used. See your attribute's marshaler class for details.
      def serialize(raw_value)
        @marshaler.serialize(raw_value)
      end

      # @api private
      def extract(dynamodb_item)
        dynamodb_item[@database_name]
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

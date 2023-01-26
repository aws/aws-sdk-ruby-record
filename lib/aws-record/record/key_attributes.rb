# frozen_string_literal: true

module Aws
  module Record
    # @api private
    class KeyAttributes
      attr_reader :keys

      def initialize(model_attributes)
        @keys = {}
        @model_attributes = model_attributes
      end

      def hash_key
        @hash_key
      end

      def hash_key_attribute
        @model_attributes.attribute_for(hash_key)
      end

      def range_key
        @range_key
      end

      def range_key_attribute
        @model_attributes.attribute_for(range_key)
      end

      def hash_key=(value)
        @keys[:hash] = value
        @hash_key = value
      end

      def range_key=(value)
        @keys[:range] = value
        @range_key = value
      end
    end
  end
end

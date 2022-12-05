# Copyright 2015-2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
    class BatchRead
      def initialize(client:)
        @client = client
      end

      def find(klass, **key)
        item_key = format_key(klass, key)
        store_item_class(klass, key)
        operations[klass.table_name] ||= { keys: [] }
        operations[klass.table_name][:keys] << item_key
        puts "Item Classes: #{item_classes}"
      end

      def execute!
        result = @client.batch_get_item(request_items: operations)
        puts result.responses
        @operations = result.unprocessed_keys
        self
      end

      def unprocessed_keys
        operations
      end

      def items
        @items ||= []
      end

      private
      def operations
        @operations ||= {}
      end

      # keeps track of all the item information
      # such as class name, keys and table name
      # before it sends off
      def item_classes
        @item_classes ||= {}
      end

      # logic that stores item info under item_keys
      # also checks to see if there's items with same keys & table name
      # but if it has different class name, should throw an error
      def store_item_class(klass, key)
      end

      def format_key(klass, key)
        item_key = {}
        attributes = klass.attributes
        klass.keys.each_value do |attr_sym|
          unless key[attr_sym]
            raise Errors::KeyMissing.new(
              "Missing required key #{attr_sym} in #{key}"
            )
          end
          attr_name = attributes.storage_name_for(attr_sym)
          item_key[attr_name] = attributes.attribute_for(attr_sym).
            serialize(key[attr_sym])
        end
        item_key
      end

      # finds the key and returns info to
      def find_item_class
      end

      def build_item
      end

    end
  end
end
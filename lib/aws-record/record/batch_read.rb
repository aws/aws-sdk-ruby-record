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
      # include ItemOperations::ItemOperationsClassMethods

      def initialize(client:)
        @client = client
      end

      def find(klass, **key)
        item_key = format_key(klass, key)
        store_item_class(klass, item_key)
        operations[klass.table_name] ||= { keys: [] }
        operations[klass.table_name][:keys] << item_key
      end

      def execute!
        result = @client.batch_get_item(request_items: operations)
        build_items(result.responses)
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

      def item_classes
        @item_classes ||= {}
      end

      def store_item_class(klass, key)
        if item_classes.include?(klass.table_name)
          item_classes[klass.table_name].each do | item |
            if item[:keys] == key && item[:class] != klass
              raise 'Provided item keys is a duplicate request'
            end
          end
        end
        item_classes[klass.table_name] ||= []
        item_classes[klass.table_name] << {keys: key, class: klass}
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

      def find_item_class(table, item)
        item_class = nil
        item_classes[table].find do |item_info|
          if item >= item_info[:keys]
            item_class = item_info[:class]
          end
        end
        item_class
      end

      def build_items(item_responses)
        item_responses.each do | table, unprocessed_items |
          unprocessed_items.each do |item|
            item_class = find_item_class(table, item)
            if item_class.nil?
              raise 'Item Class was not found'
            end
            new_item_opts = {}
            item.each do |db_name, value|
              name = item_class.attributes.db_to_attribute_name(db_name)
              new_item_opts[name] = value
            end
            item = item_class.new(new_item_opts)
            item.clean!
            items << item
          end
        end
      end

    end
  end
end
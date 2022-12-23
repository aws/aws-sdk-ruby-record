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

      def initialize(opts = {})
        @client = opts[:client]
      end

      def find(klass, key = {})
        unprocessed_key = format_unprocessed_key(klass, key)
        store_unprocessed_key(klass, unprocessed_key)
        store_item_class(klass, unprocessed_key)
      end

      def execute!
        if unprocessed_keys.count > 100
          operation_keys = unprocessed_keys[0..99].dup
          @unprocessed_keys = unprocessed_keys[100..-1].dup
        else
          operation_keys = unprocessed_keys.dup
          @unprocessed_keys.clear
        end

        operations = build_operations(operation_keys)
        result = @client.batch_get_item(request_items: operations)
        build_items(result.responses)

        unless result.unprocessed_keys.nil?
          update_unprocessed_keys(result.unprocessed_keys)
        end

        self
      end

      def complete?
        unprocessed_keys.none?
      end

      def items
        @items ||= []
      end

      private
      def unprocessed_keys
        @unprocessed_keys ||=[]
      end

      def item_classes
        @item_classes ||= {}
      end

      def format_unprocessed_key(klass, key)
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

      def store_unprocessed_key(klass, unprocessed_key)
        unprocessed_keys << {:keys => unprocessed_key, :table_name => klass.table_name}
      end

      def store_item_class(klass, key)
        if item_classes.include?(klass.table_name)
          item_classes[klass.table_name].each do |item|
            if item[:keys] == key && item[:class] != klass
              raise 'Provided item keys is a duplicate request'
            end
          end
        end
        item_classes[klass.table_name] ||= []
        item_classes[klass.table_name] << {keys: key, class: klass}
      end

      def build_operations(keys)
        operations = {}
        keys.each do | key |
          operations[key[:table_name]] ||= { keys: [] }
          operations[key[:table_name]][:keys] << key[:keys]
        end
        operations
      end

      def build_items(item_responses)
        item_responses.each do |table, unprocessed_items|
          unprocessed_items.each do |item|
            item_class = find_item_class(table, item)
            if item_class.nil?
              raise 'Item Class was not found'
            end
            item = build_item(item, item_class)
            items << item
          end
        end
      end

      def update_unprocessed_keys(keys)
        keys.each do | table_name, table_values |
          table_values.keys.each do | key |
            formatted_key = {:keys => key, :table_name => table_name}
            unprocessed_keys << formatted_key
          end
        end
      end

      def find_item_class(table, item)
        item_class = nil
        item_classes[table].find do |item_info|
          if item.merge(item_info[:keys]) == item
            item_class = item_info[:class]
            break
          end
        end
        item_class
      end

      def build_item(item, item_class)
        new_item_opts = {}
        item.each do |db_name, value|
          name = item_class.attributes.db_to_attribute_name(db_name)
          new_item_opts[name] = value
        end
        item = item_class.new(new_item_opts)
        item.clean!
        item
      end

    end
  end
end
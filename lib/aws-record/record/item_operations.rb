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
    module ItemOperations

      # @api private
      def self.included(sub_class)
        sub_class.extend(ItemOperationsClassMethods)
        sub_class.instance_variable_set("@errors", [])
      end

      # Saves this instance of an item to Amazon DynamoDB using the
      # {http://docs.aws.amazon.com/sdkforruby/api/Aws/DynamoDB/Client.html#put_item-instance_method Aws::DynamoDB::Client#put_item}
      # API. Uses this item instance's attributes in order to build the request
      # on your behalf.
      #
      # @raise [Aws::Record::Errors::KeyMissing] if a required key attribute
      #  does not have a value within this item instance.
      def save!
        dynamodb_client.put_item(
          table_name: self.class.table_name,
          item: build_item_for_save
        )
      end

      # Attempts to save this record like #save!, but instead sets record as
      # invalid. Matches style of ActiveRecord save and save! methods.
      #
      def save
        save!
      rescue Errors::KeyMissing => e
        errors << e.message
      end

      # Is the record a valid record. True if #save was successful, false if
      # Aws::Record::Errors::KeyMissing when using #save.
      #
      def valid?
        errors.empty?
      end

      # Deletes the item instance that matches the key values of this item
      # instance in Amazon DynamoDB. Uses the
      # {http://docs.aws.amazon.com/sdkforruby/api/Aws/DynamoDB/Client.html#delete_item-instance_method Aws::DynamoDB::Client#delete_item}
      # API.
      def delete!
        dynamodb_client.delete_item(
          table_name: self.class.table_name,
          key: key_values
        )
        true
      end

      private
      def build_item_for_save
        validate_key_values
        attributes = self.class.attributes
        @data.inject({}) do |acc, name_value_pair|
          attr_name, raw_value = name_value_pair
          db_name = attributes[attr_name].database_name
          acc[db_name] = attributes[attr_name].serialize(raw_value)
          acc
        end
      end

      def key_values
        validate_key_values
        attributes = self.class.attributes
        self.class.keys.inject({}) do |acc, (_, attr_name)|
          db_name = attributes[attr_name].database_name
          acc[db_name] = attributes[attr_name].serialize(@data[attr_name])
          acc
        end
      end

      def validate_key_values
        missing = missing_key_values
        unless missing.empty?
          raise Errors::KeyMissing.new(
            "Missing required keys: #{missing.join(', ')}"
          )
        end
      end

      def missing_key_values
        self.class.keys.inject([]) do |acc, key|
          acc << key.last if @data[key.last].nil?
          acc
        end
      end

      def errors
        self.class.instance_variable_get("@errors")
      end

      module ItemOperationsClassMethods

        # @example Usage Example
        #   class MyModel
        #     include Aws::Record
        #     integer_attr :id,   hash_key: true
        #     string_attr  :name, range_key: true
        #   end
        #
        #   MyModel.find(id: 1, name: "First")
        #
        # @param [Hash] opts attribute-value pairs for the key you wish to
        #  search for.
        # @return [Aws::Record] builds and returns an instance of your model.
        # @raise [Aws::Record::Errors::KeyMissing] if your option parameters do
        #  not include all table keys.
        def find(opts)
          key = {}
          @keys.each_value do |attr_sym|
            unless opts[attr_sym]
              raise Errors::KeyMissing.new(
                "Missing required key #{attr_sym} in #{opts}"
              )
            end
            attr_name = attr_sym.to_s
            key[attr_name] = attributes[attr_sym].serialize(opts[attr_sym])
          end
          request_opts = {
            table_name: table_name,
            key: key
          }
          resp = dynamodb_client.get_item(request_opts)
          if resp.item.nil?
            nil
          else
            build_item_from_resp(resp)
          end
        end

        private
        def build_item_from_resp(resp)
          record = new
          data = record.instance_variable_get("@data")
          attributes.each do |name, attr|
            data[name] = attr.extract(resp.item)
          end
          record
        end
      end

    end
  end
end

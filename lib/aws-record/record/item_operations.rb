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

      # Saves this instance of an item to Amazon DynamoDB. If this item is "new"
      #  as defined by having new or altered key attributes, will attempt a
      #  conditional
      #  {http://docs.aws.amazon.com/sdkforruby/api/Aws/DynamoDB/Client.html#put_item-instance_method Aws::DynamoDB::Client#put_item}
      #  call, which will not overwrite an existing item. If the item only has
      #  altered non-key attributes, will perform an
      #  {http://docs.aws.amazon.com/sdkforruby/api/Aws/DynamoDB/Client.html#update_item-instance_method Aws::DynamoDB::Client#update_item}
      #  call. Uses this item instance's attributes in order to build the
      #  request on your behalf.
      #
      # You can use the +:force+ option to perform a simple put/overwrite
      #  without conditional validation or update logic.
      #
      # @param [Hash] opts
      # @option opts [Boolean] :force if true, will save as a put operation and
      #  overwrite any existing item on the remote end. Otherwise, and by
      #  default, will either perform a conditional put or an update call.
      # @raise [Aws::Record::Errors::KeyMissing] if a required key attribute
      #  does not have a value within this item instance.
      # @raise [Aws::Record::Errors::ItemAlreadyExists] if a conditional put
      #  fails because the item exists on the remote end.
      def save!(opts = {})
        force = opts[:force]
        expect_new = expect_new_item?
        if force
          dynamodb_client.put_item(
            table_name: self.class.table_name,
            item: build_item_for_save
          )
        elsif expect_new
          put_opts = {
            table_name: self.class.table_name,
            item: build_item_for_save
          }.merge(prevent_overwrite_expression)
          begin
            dynamodb_client.put_item(put_opts)
          rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException => e
            raise Errors::ItemAlreadyExists.new(
              "Conditional #put_item call failed, an item with the same key"\
                " already exists in the table. Either load and update this"\
                " item, or include the :force option to clobber the remote"\
                " item."
            )
          end
        else
          dynamodb_client.update_item(
            table_name: self.class.table_name,
            key: key_values,
            attribute_updates: dirty_changes_for_update
          )
        end
      end

      # Saves this instance of an item to Amazon DynamoDB. If this item is "new"
      #  as defined by having new or altered key attributes, will attempt a
      #  conditional
      #  {http://docs.aws.amazon.com/sdkforruby/api/Aws/DynamoDB/Client.html#put_item-instance_method Aws::DynamoDB::Client#put_item}
      #  call, which will not overwrite an existing item. If the item only has
      #  altered non-key attributes, will perform an
      #  {http://docs.aws.amazon.com/sdkforruby/api/Aws/DynamoDB/Client.html#update_item-instance_method Aws::DynamoDB::Client#update_item}
      #  call. Uses this item instance's attributes in order to build the
      #  request on your behalf.
      #
      # You can use the +:force+ option to perform a simple put/overwrite
      #  without conditional validation or update logic.
      #
      # In the case where persistence fails, will populate the +errors+ array
      #  with any generated error messages, and will cause +#valid?+ to return
      #  false until there is a successful save.
      #
      # @param [Hash] opts
      # @option opts [Boolean] :force if true, will save as a put operation and
      #  overwrite any existing item on the remote end. Otherwise, and by
      #  default, will either perform a conditional put or an update call.
      def save(opts = {})
        result = save!(opts)
        errors.clear
        result
      rescue Errors::RecordError => e
        errors << e.message
        false
      end

      # Checks if the record is a valid record. +false+ if most recent +#save+
      # call raised errors, or if there are missing keys. +true+ otherwise.
      def valid?
        errors.empty? && missing_key_values.empty?
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

      def errors
        self.class.instance_variable_get("@errors")
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

      private
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

      def expect_new_item?
        # Algorithm: Are keys dirty? If so, we treat as new.
        self.class.keys.any? do |_, attr_name|
          attribute_dirty?(attr_name)
        end
      end

      def prevent_overwrite_expression
        conditions = []
        expression_attribute_names = {}
        # Hash Key
        conditions << "attribute_not_exists(#H)"
        expression_attribute_names["#H"] = self.class.hash_key.database_name
        # Range Key
        if self.class.range_key
          conditions << "attribute_not_exists(#R)"
          expression_attribute_names["#R"] = self.class.range_key.database_name
        end
        {
          condition_expression: conditions.join(" and "),
          expression_attribute_names: expression_attribute_names
        }
      end

      def dirty_changes_for_update
        attributes = self.class.attributes
        ret = dirty.inject({}) do |acc, attr_name|
          key = attributes[attr_name].database_name
          value = {
            value: attributes[attr_name].serialize(@data[attr_name]),
            action: "PUT"
          }
          acc[key] = value
          acc
        end
        ret
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

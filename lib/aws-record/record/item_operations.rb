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
      end

      # Saves this instance of an item to Amazon DynamoDB. If this item is "new"
      # as defined by having new or altered key attributes, will attempt a
      # conditional
      # {http://docs.aws.amazon.com/sdkforruby/api/Aws/DynamoDB/Client.html#put_item-instance_method Aws::DynamoDB::Client#put_item}
      # call, which will not overwrite an existing item. If the item only has
      # altered non-key attributes, will perform an
      # {http://docs.aws.amazon.com/sdkforruby/api/Aws/DynamoDB/Client.html#update_item-instance_method Aws::DynamoDB::Client#update_item}
      # call. Uses this item instance's attributes in order to build the
      # request on your behalf.
      #
      # You can use the +:force+ option to perform a simple put/overwrite
      # without conditional validation or update logic.
      #
      # @param [Hash] opts
      # @option opts [Boolean] :force if true, will save as a put operation and
      #  overwrite any existing item on the remote end. Otherwise, and by
      #  default, will either perform a conditional put or an update call.
      # @raise [Aws::Record::Errors::KeyMissing] if a required key attribute
      #  does not have a value within this item instance.
      # @raise [Aws::Record::Errors::ConditionalWriteFailed] if a conditional
      #  put fails because the item exists on the remote end.
      # @raise [Aws::Record::Errors::ValidationError] if the item responds to
      #  +:valid?+ and that call returned false. In such a case, checking root
      #  cause is dependent on the validation library you are using.
      def save!(opts = {})
        ret = save(opts)
        if ret
          ret
        else
          raise Errors::ValidationError.new("Validation hook returned false!")
        end
      end

      # Saves this instance of an item to Amazon DynamoDB. If this item is "new"
      # as defined by having new or altered key attributes, will attempt a
      # conditional
      # {http://docs.aws.amazon.com/sdkforruby/api/Aws/DynamoDB/Client.html#put_item-instance_method Aws::DynamoDB::Client#put_item}
      # call, which will not overwrite an existing item. If the item only has
      # altered non-key attributes, will perform an
      # {http://docs.aws.amazon.com/sdkforruby/api/Aws/DynamoDB/Client.html#update_item-instance_method Aws::DynamoDB::Client#update_item}
      # call. Uses this item instance's attributes in order to build the
      # request on your behalf.
      #
      # You can use the +:force+ option to perform a simple put/overwrite
      # without conditional validation or update logic.
      #
      # @param [Hash] opts
      # @option opts [Boolean] :force if true, will save as a put operation and
      #  overwrite any existing item on the remote end. Otherwise, and by
      #  default, will either perform a conditional put or an update call.
      # @return false if the record is invalid as defined by an attempt to call
      #  +valid?+ on this item, if that method exists. Otherwise, returns client
      #  call return value.
      def save(opts = {})
        if _invalid_record?(opts)
          false
        else
          _perform_save(opts)
        end
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
      def _invalid_record?(opts)
        if self.respond_to?(:valid?)
          if !self.valid?
            true
          else
            false
          end
        else
          false
        end
      end

      def _perform_save(opts)
        force = opts[:force]
        expect_new = expect_new_item?
        if force
          dynamodb_client.put_item(
            table_name: self.class.table_name,
            item: _build_item_for_save
          )
        elsif expect_new
          put_opts = {
            table_name: self.class.table_name,
            item: _build_item_for_save
          }.merge(prevent_overwrite_expression)
          begin
            dynamodb_client.put_item(put_opts)
          rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException => e
            raise Errors::ConditionalWriteFailed.new(
              "Conditional #put_item call failed! Check that conditional write"\
                " conditions are met, or include the :force option to clobber"\
                " the remote item."
            )
          end
        else
          update_pairs = _dirty_changes_for_update
          update_tuple = self.class.send(
            :_build_update_expression,
            update_pairs
          )
          if update_tuple
            uex, exp_attr_names, exp_attr_values = update_tuple
            dynamodb_client.update_item(
              table_name: self.class.table_name,
              key: key_values,
              update_expression: uex,
              expression_attribute_names: exp_attr_names,
              expression_attribute_values: exp_attr_values
            )
          else
            dynamodb_client.update_item(
              table_name: self.class.table_name,
              key: key_values
            )
          end
        end
      end

      def _build_item_for_save
        validate_key_values
        attributes = self.class.attributes
        _populate_default_values(attributes)
        @data.inject({}) do |acc, name_value_pair|
          attr_name, raw_value = name_value_pair
          attribute = attributes[attr_name]
          if !raw_value.nil? || attribute.persist_nil?
            db_name = attribute.database_name
            acc[db_name] = attribute.serialize(raw_value)
          end
          acc
        end
      end

      def _populate_default_values(attributes)
        attributes.each do |attr_name, attribute|
          if !attribute.default_value.nil? && @data[attribute.name].nil?
            @data[attr_name] = attribute.default_value
          end
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

      def _dirty_changes_for_update
        attributes = self.class.attributes
        ret = dirty.inject({}) do |acc, attr_name|
          acc[attr_name] = @data[attr_name]
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
            attr_name = attributes[attr_sym].database_name
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

        # @example Usage Example
        #   class MyModel
        #     include Aws::Record
        #     integer_attr :id,   hash_key: true
        #     string_attr  :name, range_key: true
        #     string_attr  :body
        #     boolean_attr :sir_not_appearing_in_this_example
        #   end
        #
        #   MyModel.update(id: 1, name: "First", body: "Hello!")
        #
        # Performs an
        # {http://docs.aws.amazon.com/sdkforruby/api/Aws/DynamoDB/Client.html#update_item-instance_method Aws::DynamoDB::Client#update_item}
        # call immediately on the table, using the attribute key/value pairs
        # provided.
        #
        # @param [Hash] opts attribute-value pairs for the update operation you
        #  wish to perform. You must include all key attributes for a valid
        #  call, then you may optionally include any other attributes that you
        #  wish to update.
        # @raise [Aws::Record::Errors::KeyMissing] if your option parameters do
        #  not include all table keys.
        def update(opts)
          key = {}
          updates = {}
          @keys.each_value do |attr_sym|
            unless value = opts.delete(attr_sym)
              raise Errors::KeyMissing.new(
                "Missing required key #{attr_sym} in #{opts}"
              )
            end
            attr_name = attributes[attr_sym].database_name
            key[attr_name] = attributes[attr_sym].serialize(value)
          end
          request_opts = {
            table_name: table_name,
            key: key
          }
          update_tuple = _build_update_expression(opts)
          unless update_tuple.nil?
            uex, exp_attr_names, exp_attr_values = update_tuple
            request_opts[:update_expression] = uex
            request_opts[:expression_attribute_names] = exp_attr_names
            request_opts[:expression_attribute_values] = exp_attr_values
          end
          dynamodb_client.update_item(request_opts)
        end

        private
        def _build_update_expression(attr_value_pairs)
          set_expressions = []
          remove_expressions = []
          exp_attr_names = {}
          exp_attr_values = {}
          name_sub_token = "UE_A"
          value_sub_token = "ue_a"
          attr_value_pairs.each do |attr_sym, value|
            name_sub = "#" + name_sub_token
            value_sub = ":" + value_sub_token
            name_sub_token = name_sub_token.succ
            value_sub_token = value_sub_token.succ

            attribute = attributes[attr_sym]
            attr_name = attribute.database_name
            exp_attr_names[name_sub] = attr_name
            if _update_type_remove?(attribute, value)
              remove_expressions << "#{name_sub}"
            else
              set_expressions << "#{name_sub} = #{value_sub}"
              exp_attr_values[value_sub] = attribute.serialize(value)
            end
          end
          update_expressions = []
          unless set_expressions.empty?
            update_expressions << "SET " + set_expressions.join(", ")
          end
          unless remove_expressions.empty?
            update_expressions << "REMOVE " + remove_expressions.join(", ")
          end
          if update_expressions.empty?
            nil
          else
            [update_expressions.join(" "), exp_attr_names, exp_attr_values]
          end
        end

        def build_item_from_resp(resp)
          record = new
          data = record.instance_variable_get("@data")
          attributes.each do |name, attr|
            data[name] = attr.extract(resp.item)
          end
          record
        end

        def _update_type_remove?(attribute, value)
          value.nil? && !attribute.persist_nil?
        end
      end

    end
  end
end

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
        operations[klass.table_name] ||= { keys: [] }
        operations[klass.table_name][:keys] << item_key
      end

      def execute!
        result = @client.batch_get_item(request_items: operations)
        @operations = result.unprocessed_keys
        self
      end

      def unprocessed_keys
        operations
      end

      private
      def operations
        @operations ||= {}
      end

    end
  end
end
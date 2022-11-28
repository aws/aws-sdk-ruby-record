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

      def find(record)
        table_name, params = record_find_params(record)
        operations[table_name] ||= { keys: [] }
        operations[table_name][:keys] << params
      end

      def execute!
        result = @client.batch_get_item(request_items: operations)
        @operations = result.unprocessed_keys
        self
      end

      def operations
        @operations ||= {}
      end

      private
      def record_find_params(record)
        [record.class.table_name, record.key_values]
      end

    end
  end
end
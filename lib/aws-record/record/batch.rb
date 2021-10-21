# Copyright 2015-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
    class Batch
      # @param [Aws::DynamoDB::Client] client the DynamoDB SDK client.
      def initialize(client:)
        @client = client
      end

      # @example Usage Example
      #   class Breakfast
      #     include Aws::Record
      #     integer_attr :id,   hash_key: true
      #     string_attr  :name, range_key: true
      #     string_attr  :body
      #   end
      #
      #   # setup
      #   eggs = Breakfast.new(id: 1, name: "eggs").save!
      #   waffles = Breakfast.new(id: 2, name: "waffles")
      #   pancakes = Breakfast.new(id: 3, name: "pancakes")
      #   batch = Aws::Record::Batch.new(client: Breakfast.dynamodb_client)
      #
      #   # batch operations
      #   batch.write do |db|
      #     db.put(waffles)
      #     db.delete(eggs)
      #     db.put(pancakes)
      #   end
      #
      # Provides a thin wrapper to the
      # {https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/DynamoDB/Client.html#batch_write_item-instance_method Aws::DynamoDB::Client#batch_write_item}
      # method. Up to 25 +PutItem+ or +DeleteItem+ operations are supported.
      # A single rquest may write up to 16 MB of data, with each item having a
      # write limit of 400 KB.
      #
      # *Note*: this operation does not support dirty attribute handling,
      # nor does it enforce safe write operations (i.e. update vs new record
      # checks).
      #
      # This call may partially execute write operations. Failed operations
      # are returned as +Aws::Record::BatchWrite#unprocessed_items+ (i.e. the
      # table fails to meet requested write capacity). Any unprocessed
      # items may be retried by calling +Aws::Record::BatchWrite#execute!+
      # again.
      #
      # Please see
      # {https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Programming.Errors.html#Programming.Errors.BatchOperations Batch Operations and Error Handling}
      # in the DynamoDB Developer Guide for more details.
      #
      # @return [Aws::Record::BatchWrite] An instance that contains any
      #   unprocessed items and allows for a retry strategy.
      def write(&block)
        batch = BatchWrite.new(client: @client)
        block.call(batch)
        batch.execute!
      end
    end
  end
end

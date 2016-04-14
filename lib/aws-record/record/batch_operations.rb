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
    module BatchOperations

      # @api private
      def self.included(sub_class)
        sub_class.extend(BatchOperationsClassMethods)
      end

      module BatchOperationsClassMethods

        # @example Usage Example
        #   class MyModel
        #     include Aws::Record
        #     integer_attr :id,   hash_key: true
        #     string_attr  :name, range_key: true
        #   end
        #
        #   batch_writer = MyModel.batch_writer
        #   batch_writer.add(MyModel.new(...))
        #   batch_writer.save
        #
        #  or
        #
        #   items = [MyModel.new(...), MyModel.new(...)]
        #   batch_writer = MyModel.batch_writer(items)
        #   batch_writer.save
        #
        # This method sets up the ability to do batch_write_item
        # {http://docs.aws.amazon.com/sdkforruby/api/Aws/DynamoDB/Client.html#batch_write_item-instance_method Aws::DynamoDB::Client#batch_write_item},
        # populating the +:table_name+ parameter from the model class. This
        # deviates slightly from the Aws::DynamoDB::Client#batch_write_item
        # in that it only allows items of the given model class to be written
        # from this method.
        #
        # @param [Array] items optional list of instances of the model to
        #  batch_write.
        # @return [Aws::Record::BatchWriter] an enumerable collection of the
        #   items to batch write to DynamoDB.
        # @raise [ArgumentError] if an item exists in items that is not of the
        #  same class as the current record.
        def batch_writer(items = [])
          BatchWriter.new(self, dynamodb_client, items)
        end
      end

    end
  end
end

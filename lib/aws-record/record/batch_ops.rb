module Aws
  module Record
    module Batch

      def self.included(sub_class)
        sub_class.extend(BatchClassMethods)
      end

      module BatchClassMethods

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

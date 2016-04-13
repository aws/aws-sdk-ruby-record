module Aws
  module Record
    class BatchWriter < Batch
      include Enumerable

      # This method calls
      # {http://docs.aws.amazon.com/sdkforruby/api/Aws/DynamoDB/Client.html#batch_write_item-instance_method Aws::DynamoDB::Client#batch_write_item}},
      # on the items stored in this BatchWriter. Note that this method does
      # not support delete_request, only put_request and that only items
      # of the same class can be written using this method. The following
      # failure scenarios are prevented before being sent to DynamoDB:
      #
      #   - One or more tables specified in the BatchWriteItem request does not
      #      exist.
      #   - You try to perform multiple operations on the same item in the same
      #      BatchWriteItem request. For example, you cannot put and delete the
      #      same item in the same BatchWriteItem request.
      #   - There are more than 25 requests in the batch.
      #   - Primary key attributes specified on an item in the request do not
      #      match those in the corresponding table's primary key schema.
      #
      # This method will not prevent the following failure scenarios and will
      # need to be handled separately:
      #
      #   - Any individual item in a batch exceeds 400 KB.
      #   - The total request size exceeds 16 MB.
      #
      # @param [Hash] opts options to pass on to the client call to
      #   +#batch_item_write+. See the documentation above in the AWS SDK for
      #   Ruby V2.
      # @opts retry_count the number of retries to attempt on failed write
      # @return
      def save!(opts = {})
        validate_items
        @items.each_slice(25) do
          batch_write_items(opts)
        end
      end

      private
      def batch_write_items(opts)
        try_count = opts.delete(:retry_count) { |_| 4 }
        (0..try_count).each do |i|
          sleep i**2
          dynamodb_client.batch_write_item(formatted_request(opts))
        end
      end

      def formatted_request(opts)
        {
          request_items: {
            self.class.table_name => @items.map do |item|
              request_item(item)
            end
          }
        }.merge(opts)
      end

      def request_item(item)
        {
          put_request: {
            item: item.to_h
          }
        }
      end

      def validate_items
        @items.each do |item|
          raise ValidationError unless item.valid?
        end
      end

    end
  end
end

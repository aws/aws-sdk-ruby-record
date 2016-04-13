module Aws
  module Record
    class BatchWriter < Batch
      include Enumerable

      # Writer states
      PENDING_STATE = 'PENDING'.freeze
      SUCCESSFUL_SEND_STATE = 'SUCCESSFUL'.freeze
      ERROR_SEND_STATE = 'ERROR'.freeze

      # DynamoDb item request limit
      ITEM_REQUEST_LIMIT = 25

      # Read the state of the BatchWriter
      attr_reader :state

      def intialize
        super
        @state = PENDING_STATE
        @errors = []
      end

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
      # If any items are not successfully submitted, a RuntimeError is raised
      # and the BatchWriter can be inspected to see what the errors were.
      # A call to #errors will return an array of response objects that contain
      # the errors. See the documentation for Response at
      # http://docs.aws.amazon.com/sdkforruby/api/Seahorse/Client/Response.html
      #
      # @param [Hash] opts options to pass on to the client call to
      #   +#batch_item_write+. See the documentation above in the AWS SDK for
      #   Ruby V2.
      # @opts retry_count the number of retries to attempt on failed write
      # @return true if successful
      # @raise RuntimeError if unsuccessful in submitting all items
      def save!(opts = {})
        raise "can't submit if writer in #{@state} state." unless pending?
        validate_items
        retry_items = []

        @items.each_slice(ITEM_REQUEST_LIMIT) do |items|
          item_requests_array = items.map { |item| request_item(item) }
          @retry_items += batch_write_items(item_requests_array, opts)
        end
        retry_and_return_or_raise(retry_items, opts)
      end

      def pending?
        @state == PENDING_STATE
      end

      def errors
        @errors
      end

      def unprocesssed_items
        @errors.map(&:unprocessed_items)
      end

      private
      def batch_write_items(item_requests_array, opts)
        response = batch_write(item_requests_array, opts)
        response.successful? ? response.unprocessed_items : item_requests_array
      end

      def batch_write(item_requests_array, opts)
        dynamodb_client.batch_write_item(
          formatted_request(item_requests_array, opts)
        )
      end

      def formatted_request(item_requests_array, opts)
        {
          request_items: {
            @model.class.table_name => item_requests_array
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

      def retry_and_return_or_raise(item_requests_array, opts)
        responses = []
        item_requests_array.each_slice(ITEM_REQUEST_LIMIT) do |items|
          responses << retry_chunk(items, opts)
        end
        if failures?(responses)
          @errors += responses.reject(&:successful?)
          @state = ERROR_SEND_STATE
          raise 'Failed to submit all items'
        end
        @state = SUCCESSFUL_SEND_STATE
        true
      end

      def failures?(responses)
        responses.any? do |response|
          !response.successful? || response.unprocessed_items.empty?
        end
      end

      def retry_chunk(item_requests_array, opts)
        response = nil
        (0..4).each do |i|
          sleep i**2
          response = batch_write(item_requests_array, opts)
          break if response.successful? && response.unprocessed_items.empty?
          response.unprocessed_items = item_requests_array
        end
        response
      end

    end
  end
end

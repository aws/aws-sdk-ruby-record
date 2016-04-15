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
    class BatchWriter < Batch
      include Enumerable

      # Writer states
      PENDING_STATE = 'PENDING'.freeze
      SUCCESSFUL_SEND_STATE = 'SUCCESSFUL'.freeze
      ERROR_SEND_STATE = 'ERROR'.freeze

      # DynamoDb item request limit
      ITEM_REQUEST_LIMIT = 25

      def initialize(model, client, items = [])
        super(model, client, items)
        @state = PENDING_STATE
        @errors = []
        @error_struct = Struct.new(:error, :data, :unprocessed_items) do
          def successful?
            false
          end
        end
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
      # @raise RuntimeError if unsuccessful in submitting all items
      def save!(opts = {})
        raise "can't submit if writer in #{@state} state." unless pending?
        validate_items
        # the -1 is to make it equal the number of retries requested
        @retry_times = (opts.delete(:retry_count) { |_| 4 } - 1)
        retry_items = send_chunks(opts)
        responses = retry_failed_requests(retry_items, opts)
        analyze_result(responses)
      end

      # Perform the save! function but capture the error that is raised on
      # unsuccessful save.
      def save(opts = {})
        save!(opts)
        true
      rescue RuntimeError
        false
      end

      def error?
        @state == ERROR_SEND_STATE
      end

      # Get a hash of the responses that didn't work along with their
      # unprocessed items. Mimics ActiveRecord design.
      def errors
        @errors.map do |err|
          {
            error: err.error,
            data: err.data,
            unprocesssed_items: err.unprocessed_items
          }
        end
      end

      def pending?
        @state == PENDING_STATE
      end

      def unprocessed_items
        # Will only have one error if error is RecordError
        return [] if @errors.empty? || @errors.first.data.is_a?(Errors::RecordError)
        # Should be more than one error if failed_items.size > 25
        @errors.map(&:unprocessed_items)
      end

      def valid?
        @state == SUCCESSFUL_SEND_STATE
      end

      private
      def alert_errors(responses)
        @errors += responses.reject(&:successful?)
        @state = ERROR_SEND_STATE
        raise Errors::SubmissionError
      end

      def analyze_result(responses)
        alert_errors(responses) if failures?(responses)
        @state = SUCCESSFUL_SEND_STATE
      end

      def batch_write(item_requests_array, opts)
        @client.batch_write_item(
          formatted_request(item_requests_array, opts)
        )
      # Retry in instance where client raise_response_error is true
      rescue Aws::DynamoDB::Errors::ProvisionedThroughputExceededException => e
        @error_struct.new(e.class, e, item_requests_array)
      end

      def batch_write_items(item_requests_array, opts)
        response = batch_write(item_requests_array, opts)
        if response.successful?
          response.unprocessed_items[@model.table_name] || []
        else
          item_requests_array
        end
      end

      def capture_validation_error(e)
        @state = ERROR_SEND_STATE
        @errors << @error_struct.new(e.class, e, @items)
      end

      def failures?(responses)
        responses.any? do |response|
          !response.successful? || response.unprocessed_items.empty?
        end
      end

      def formatted_request(item_requests_array, opts)
        {
          request_items: {
            @model.table_name => item_requests_array
          }
        }.merge(opts)
      end

      def request_item(item)
        {
          put_request: {
            item: item.build_item_for_save
          }
        }
      end

      def retry_failed_requests(item_requests_array, opts)
        responses = []
        (0..@retry_times).each do |i|
          sleep(i * 1.5)
          responses = retry_by_chunks(item_requests_array, opts)
          break unless failures?(responses)
        end
        responses
      end

      def retry_by_chunks(item_requests_array, opts)
        responses = []
        item_requests_array.each_slice(ITEM_REQUEST_LIMIT) do |items|
          responses << retry_chunk(items, opts)
        end
        responses
      end

      def retry_chunk(item_requests_array, opts)
        response = batch_write(item_requests_array, opts)
        response.unprocessed_items ||= item_requests_array unless response.successful?
        response
      end

      def send_chunks(opts)
        retry_items = []
        @items.each_slice(ITEM_REQUEST_LIMIT) do |items|
          item_requests_array = items.map { |item| request_item(item) }
          retry_items += batch_write_items(item_requests_array, opts)
        end
        retry_items
      end

      def validate_items
        @items.each do |item|
          raise Errors::ValidationError unless item.valid?
        end
      rescue Errors::ValidationError => e
        capture_validation_error(e)
        raise e
      end

      def retry_and_return_or_raise(item_requests_array, opts)
        responses = []
        item_requests_array.each_slice(ITEM_REQUEST_LIMIT) do |items|
          responses << retry_chunk(items, opts)
        end
        responses
      end

    end
  end
end

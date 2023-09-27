# frozen_string_literal: true

module Aws
  module Record
    class BatchWrite
      # @param [Hash] opts
      # @option opts [Aws::DynamoDB::Client] client the DynamoDB SDK client.
      def initialize(opts = {})
        @client = opts[:client]
      end

      # Append a +PutItem+ operation to a batch write request.
      #
      # See {Batch.write} for example usage.
      #
      # @param [Aws::Record] record a model class that includes {Aws::Record}.
      def put(record)
        table_name, params = record_put_params(record)
        operations[table_name] ||= []
        operations[table_name] << { put_request: params }
      end

      # Append a +DeleteItem+ operation to a batch write request.
      #
      # See {Batch.write} for example usage.
      # @param [Aws::Record] record a model class that includes {Aws::Record}.
      def delete(record)
        table_name, params = record_delete_params(record)
        operations[table_name] ||= []
        operations[table_name] << { delete_request: params }
      end

      # Perform a +batch_write_item+ request.
      #
      # See {Batch.write} for example usage.
      # @return [Aws::Record::BatchWrite] an instance that provides access to
      #   unprocessed items and allows for retries.
      def execute!
        result = @client.batch_write_item(request_items: operations)
        @operations = result.unprocessed_items
        self
      end

      # Indicates if all items have been processed.
      #
      # See {Batch.write} for example usage.
      # @return [Boolean] +true+ if +unprocessed_items+ is empty, +false+
      #   otherwise
      def complete?
        unprocessed_items.values.none?
      end

      # Returns all +DeleteItem+ and +PutItem+ operations that have not yet been
      # processed successfully.
      #
      # See {Batch.write} for example usage.
      # @return [Hash] All operations that have not yet successfully completed.
      def unprocessed_items
        operations
      end

      private

      def operations
        @operations ||= {}
      end

      def record_delete_params(record)
        [record.class.table_name, { key: record.key_values }]
      end

      def record_put_params(record)
        [record.class.table_name, { item: record.save_values }]
      end
    end
  end
end

# frozen_string_literal: true

module Aws
  module Record
    class Batch
      extend ClientConfiguration

      class << self
        # Provides a thin wrapper to the
        # {https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/DynamoDB/Client.html#batch_write_item-instance_method Aws::DynamoDB::Client#batch_write_item}
        # method. Up to 25 +PutItem+ or +DeleteItem+ operations are supported.
        # A single request may write up to 16 MB of data, with each item having a
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
        # again. You can determine if the request needs to be retried by calling
        # the +Aws::Record::BatchWrite#complete?+ method - which returns +true+
        # when all operations have been completed.
        #
        # Please see
        # {https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Programming.Errors.html#Programming.Errors.BatchOperations Batch Operations and Error Handling}
        # in the DynamoDB Developer Guide for more details.
        #
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
        #
        #   # batch operations
        #   operation = Aws::Record::Batch.write(client: Breakfast.dynamodb_client) do |db|
        #     db.put(waffles)
        #     db.delete(eggs)
        #     db.put(pancakes)
        #   end
        #
        #   # unprocessed items can be retried by calling Aws::Record::BatchWrite#execute!
        #   operation.execute! until operation.complete?
        #
        # @param [Hash] opts the options you wish to use to create the client.
        #  Note that if you include the option +:client+, all other options
        #  will be ignored. See the documentation for other options in the
        #  {https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/DynamoDB/Client.html#initialize-instance_method AWS SDK for Ruby}.
        # @option opts [Aws::DynamoDB::Client] :client allows you to pass in your
        #  own pre-configured client.
        #
        # @return [Aws::Record::BatchWrite] An instance that contains any
        #   unprocessed items and allows for a retry strategy.
        def write(opts = {}, &block)
          batch = BatchWrite.new(client: _build_client(opts))
          block.call(batch)
          batch.execute!
        end

        # Provides support for the
        # {https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/DynamoDB/Client.html#batch_get_item-instance_method
        # Aws::DynamoDB::Client#batch_get_item} for aws-record models.
        #
        # The +batch_get_item+ supports up to 100 operations and a single operation can
        # retrieve up to 16 MB of data.
        #
        # +Aws::Record::BatchRead+ can take more than 100 item keys. The first 100 requests
        # will be processed and the remaining requests will be stored. Any unprocessed keys can
        # be processed by calling +Aws::Record::BatchRead#execute!+.
        #
        # You can determine if there are any unprocessed keys by calling the
        # +Aws::Record::BatchRead#complete?+ method - which returns +true+
        # when all operations have been completed.
        #
        # All processed operations can be accessed by +items+ - which is an array of modeled
        # items from the response. The items will be unordered since DynamoDB does not return
        # items in any particular order.
        #
        # If a requested item does not exist in the database, it is not returned in the response.
        #
        # If there is a returned item from the call and there's no reference model class
        # to be found, the item will not show up under +items+.
        #
        # +Aws::Record::BatchRead+ is also enumerable and handles pagination.
        #
        # When using +Aws::Record::BatchRead#each+, any pending item keys will be automatically
        # processed and the new items will be added to +items+.
        # @example Usage Example
        #   class Lunch
        #     include Aws::Record
        #     integer_attr :id,   hash_key: true
        #     string_attr  :name, range_key: true
        #   end
        #
        #   class Dessert
        #     include Aws::Record
        #     integer_attr :id,   hash_key: true
        #     string_attr  :name, range_key: true
        #   end
        #
        #   # batch operations
        #   operation = Aws::Record::Batch.read do |db|
        #     db.find(Lunch, id: 1, name: 'Papaya Salad')
        #     db.find(Lunch, id: 2, name: 'BLT Sandwich')
        #     db.find(Dessert, id: 1, name: 'Apple Pie')
        #   end
        #
        #   # BatchRead is enumerable and handles pagination
        #   operation.each { |item| item.id }
        #
        #   # Alternatively, BatchRead provides a lower level
        #   # interface through: execute!, complete? and items.
        #   # Unprocessed items can be processed by calling:
        #   operation.execute! until operation.complete?
        #
        # @param [Hash] opts the options you wish to use to create the client.
        #  Note that if you include the option +:client+, all other options
        #  will be ignored. See the documentation for other options in the
        #  {https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/DynamoDB/Client.html#initialize-instance_method
        #  AWS SDK for Ruby}.
        # @option opts [Aws::DynamoDB::Client] :client allows you to pass in your
        #  own pre-configured client.
        # @return [Aws::Record::BatchRead] An instance that contains modeled items
        #  from the +BatchGetItem+ result and stores unprocessed keys to be
        #  manually processed later.
        def read(opts = {}, &block)
          batch = BatchRead.new(client: _build_client(opts))
          block.call(batch)
          batch.execute!
          batch
        end

      end
    end
  end
end

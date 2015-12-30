module Aws
  module Record
    class TableMigration

      # @!attribute [rw] client
      #   @return [Aws::DynamoDB::Client] the
      #     {http://docs.aws.amazon.com/sdkforruby/api/Aws/DynamoDB/Client.html Aws::DynamoDB::Client}
      #     class used by this table migration instance.
      attr_accessor :client

      # @param [Aws::Record] model a model class that includes {Aws::Record}.
      # @param [Hash] opts
      # @option opts [Aws::DynamoDB::Client] :client Allows you to inject your
      #  own
      #  {http://docs.aws.amazon.com/sdkforruby/api/Aws/DynamoDB/Client.html Aws::DynamoDB::Client}
      #  class. If this option is not included, a client will be constructed for
      #  you with default parameters.
      def initialize(model, opts = {})
        assert_model_valid(model)
        @model = model
        @client = opts[:client] || Aws::DynamoDB::Client.new
      end

      # This method calls
      # {http://docs.aws.amazon.com/sdkforruby/api/Aws/DynamoDB/Client.html#create_table-instance_method Aws::DynamoDB::Client#create_table},
      # populating the attribute definitions and key schema based on your model
      # class, as well as passing through other parameters as provided by you.
      #
      # @param [Hash] opts options to pass on to the client call to
      #  +#create_table+. See the documentation above in the AWS SDK for Ruby
      #  V2.
      # @option opts [Hash] :provisioned_throughput This is a required argument,
      #  in which you must specify the +:read_capacity_units+ and
      #  +:write_capacity_units+ of your new table.
      def create!(opts)
        create_opts = opts.merge({
          table_name: @model.table_name,
          attribute_definitions: attribute_definitions,
          key_schema: key_schema
        })
        @client.create_table(create_opts)
      end

      # This method calls
      # {http://docs.aws.amazon.com/sdkforruby/api/Aws/DynamoDB/Client.html#update_table-instance_method Aws::DynamoDB::Client#update_table}
      # using the parameters that you provide.
      #
      # @param [Hash] opts options to pass on to the client call to
      #  +#update_table+. See the documentation above in the AWS SDK for Ruby
      #  V2.
      # @raise [Aws::Record::Errors::TableDoesNotExist] if the table does not
      #  currently exist in Amazon DynamoDB.
      def update!(opts)
        begin
          update_opts = opts.merge({
            table_name: @model.table_name
          })
          @client.update_table(update_opts)
        rescue DynamoDB::Errors::ResourceNotFoundException => e
          raise Errors::TableDoesNotExist.new(e)
        end
      end

      # This method calls
      # {http://docs.aws.amazon.com/sdkforruby/api/Aws/DynamoDB/Client.html#delete_table-instance_method Aws::DynamoDB::Client#delete_table}
      # using the table name of your model.
      #
      # @raise [Aws::Record::Errors::TableDoesNotExist] if the table did not
      #  exist in Amazon DynamoDB at the time of calling.
      def delete!
        begin
          @client.delete_table(table_name: @model.table_name)
        rescue DynamoDB::Errors::ResourceNotFoundException => e
          raise Errors::TableDoesNotExist.new(e)
        end
      end

      # This method waits on the table specified in the model to exist and be
      # marked as ACTIVE in Amazon DynamoDB. Note that this method can run for
      # several minutes if the table does not exist, and is not created within
      # the wait period.
      def wait_until_available
        @client.wait_until(:table_exists, table_name: @model.table_name)
      end

      private
      def assert_model_valid(model)
        assert_required_include(model)
        assert_keys(model)
      end

      def assert_required_include(model)
        unless model.include?(::Aws::Record)
          raise Errors::InvalidModel.new("Table models must include Aws::Record")
        end
      end

      def assert_keys(model)
        if model.hash_key.nil?
          raise Errors::InvalidModel.new("Table models must include a hash key")
        end
      end

      def attribute_definitions
        keys.map do |type, attr|
          {
            attribute_name: attr.database_name,
            attribute_type: attr.dynamodb_type
          }
        end
      end

      def key_schema
        keys.map do |type, attr|
          {
            attribute_name: attr.database_name,
            key_type: type == :hash ? "HASH" : "RANGE"
          }
        end
      end

      def keys
        @model.keys.inject({}) do |acc, (type, name)|
          acc[type] = @model.attributes[name]
          acc
        end
      end
    end
  end
end

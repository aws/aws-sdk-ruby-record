module Aws
  module Record
    class TableMigration

      attr_accessor :client

      def initialize(model, client: nil)
        assert_model_valid(model)
        @model = model
        @client = client || Aws::DynamoDB::Client.new
      end

      def create!(opts)
        create_opts = opts.merge({
          table_name: @model.table_name,
          attribute_definitions: attribute_definitions,
          key_schema: key_schema
        })
        @client.create_table(create_opts)
      end

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

      def delete!
        begin
          @client.delete_table(table_name: @model.table_name)
        rescue DynamoDB::Errors::ResourceNotFoundException => e
          raise Errors::TableDoesNotExist.new(e)
        end
      end

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

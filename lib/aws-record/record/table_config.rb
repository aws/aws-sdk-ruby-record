module Aws
  module Record
    class TableConfig

      attr_accessor :client

      class << self
        def define(&block)
          cfg = TableConfig.new
          cfg.instance_eval(&block)
          cfg.configure_client
          cfg
        end
      end

      def initialize
        @client_options = {}
      end

      def model_class(model)
        @model_class = model
      end

      def read_capacity_units(units)
        @read_capacity_units = units
      end

      def write_capacity_units(units)
        @write_capacity_units = units
      end

      def client_options(opts)
        @client_options = opts
      end

      def configure_client
        @client = Aws::DynamoDB::Client.new(@client_options)
      end

      def migrate!
        # Validate that required params are present?
        @client.create_table(_create_table_opts)
        @client.wait_until(:table_exists, table_name: @model_class.table_name)
      end

      private
      def _create_table_opts
        opts = {
          table_name: @model_class.table_name,
          provisioned_throughput: {
            read_capacity_units: @read_capacity_units,
            write_capacity_units: @write_capacity_units
          }
        }
        opts[:key_schema] = _key_schema
        opts[:attribute_definitions] = _attribute_definitions
        opts
      end

      def _key_schema
        _keys.map do |type, attr|
          {
            attribute_name: attr.database_name,
            key_type: type == :hash ? "HASH" : "RANGE"
          }
        end
      end

      def _attribute_definitions
        _keys.map do |type, attr|
          {
            attribute_name: attr.database_name,
            attribute_type: attr.dynamodb_type
          }
        end
      end

      def _keys
        @model_class.keys.inject({}) do |acc, (type, name)|
          acc[type] = @model_class.attributes.attribute_for(name)
          acc
        end
      end

    end
  end
end

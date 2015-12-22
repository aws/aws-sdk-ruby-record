module Aws
  module Record
    def self.included(sub_class)
      sub_class.extend(RecordClassMethods)
      sub_class.include(Attributes)
      sub_class.include(ItemOperations)
    end

    private
    def dynamodb_client
      self.class.dynamodb_client
    end

    module RecordClassMethods
      def table_name
        if @table_name
          @table_name
        else
          @table_name = self.name
        end
      end

      def set_table_name(name)
        @table_name = name
      end

      def provisioned_throughput
        begin
          resp = dynamodb_client.describe_table(table_name: @table_name)
          throughput = resp.table.provisioned_throughput
          return {
            read_capacity_units: throughput.read_capacity_units,
            write_capacity_units: throughput.write_capacity_units
          }
        rescue DynamoDB::Errors::ResourceNotFoundException
          raise Errors::TableDoesNotExist
        end
      end

      def configure_client(opts = {})
        provided_client = opts.delete(:client)
        opts[:user_agent_suffix] = user_agent(opts.delete(:user_agent_suffix))
        client = provided_client || Aws::DynamoDB::Client.new(opts)
        @dynamodb_client = client
      end

      def dynamodb_client
        @dynamodb_client ||= configure_client
      end
    end
  end
end

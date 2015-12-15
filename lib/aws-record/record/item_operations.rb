module Aws
  module Record
    module ItemOperations

      def configure_client(opts = {})
        provided_client = opts.delete(:client)
        client = provided_client || Aws::DynamoDB::Client.new(opts)
        self.class.instance_variable_set("@dynamodb_client", client)
      end

      def save
        dynamodb_client.put_item(
          table_name: self.class.table_name,
          item: build_item_for_save
        )
      end

      private
      def dynamodb_client
        client = self.class.instance_variable_get("@dynamodb_client")
        if client.nil?
          self.class.instance_variable_set("@dynamodb_client", configure_client)
        else
          client
        end
      end

      def build_item_for_save
        attributes = self.class.attributes
        @data.inject({}) do |acc, name_value_pair|
          attr_name, raw_value = name_value_pair
          db_name = attributes[attr_name].database_name
          acc[db_name] = attributes[attr_name].serialize(raw_value)
          acc
        end
      end

    end
  end
end

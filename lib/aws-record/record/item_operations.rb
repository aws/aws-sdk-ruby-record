module Aws
  module Record
    module ItemOperations

      def self.included(sub_class)
        sub_class.extend(ItemOperationsClassMethods)
      end

      def save
        dynamodb_client.put_item(
          table_name: self.class.table_name,
          item: build_item_for_save
        )
      end

      def delete!
        dynamodb_client.delete_item(
          table_name: self.class.table_name,
          key: key_values
        )
        true
      end

      private
      def dynamodb_client
        self.class.dynamodb_client
      end

      def build_item_for_save
        validate_key_values
        attributes = self.class.attributes
        @data.inject({}) do |acc, name_value_pair|
          attr_name, raw_value = name_value_pair
          db_name = attributes[attr_name].database_name
          acc[db_name] = attributes[attr_name].serialize(raw_value)
          acc
        end
      end

      def key_values
        validate_key_values
        attributes = self.class.attributes
        self.class.keys.inject({}) do |acc, (_, attr_name)|
          db_name = attributes[attr_name].database_name
          acc[db_name] = attributes[attr_name].serialize(@data[attr_name])
          acc
        end
      end

      def validate_key_values
        missing = missing_key_values
        unless missing.empty?
          raise Errors::KeyMissing.new(
            "Missing required keys: #{missing.join(', ')}"
          )
        end
      end

      def missing_key_values
        self.class.keys.inject([]) do |acc, key|
          acc << key.last if @data[key.last].nil?
          acc
        end
      end

      module ItemOperationsClassMethods
        def configure_client(opts = {})
          provided_client = opts.delete(:client)
          opts[:user_agent_suffix] = user_agent(opts.delete(:user_agent_suffix))
          client = provided_client || Aws::DynamoDB::Client.new(opts)
          @dynamodb_client = client
        end

        def dynamodb_client
          @dynamodb_client ||= configure_client
        end

        def find(opts)
          key = {}
          @keys.each_value do |attr_sym|
            unless opts[attr_sym]
              raise Errors::KeyMissing.new(
                "Missing required key #{attr_sym} in #{opts}"
              )
            end
            attr_name = attr_sym.to_s
            key[attr_name] = attributes[attr_sym].serialize(opts[attr_sym])
          end
          request_opts = {
            table_name: table_name,
            key: key
          }
          resp = dynamodb_client.get_item(request_opts)
          if resp.item.nil?
            nil
          else
            build_item_from_resp(resp)
          end
        end

        private
        def build_item_from_resp(resp)
          record = new
          data = record.instance_variable_get("@data")
          attributes.each do |name, attr|
            data[name] = attr.extract(resp.item)
          end
          record
        end

        def user_agent(custom)
          if custom
            custom
          else
            " aws-record/#{VERSION}"
          end
        end
      end

    end
  end
end

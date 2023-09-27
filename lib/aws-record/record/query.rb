# frozen_string_literal: true

module Aws
  module Record
    module Query
      # @api private
      def self.included(sub_class)
        sub_class.extend(QueryClassMethods)
      end

      module QueryClassMethods
        # This method calls
        # {http://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/DynamoDB/Client.html#query-instance_method
        # Aws::DynamoDB::Client#query}, populating the +:table_name+ parameter from the model
        # class, and combining this with the other parameters you provide.
        #
        # @example A query with key and filter expressions:
        #   # Example model class
        #   class ExampleTable
        #     include Aws::Record
        #     string_attr  :uuid, hash_key: true
        #     integer_attr :id,   range_key: true
        #     string_attr  :body
        #   end
        #
        #   query = ExampleTable.query(
        #     key_condition_expression: "#H = :h AND #R > :r",
        #     filter_expression: "contains(#B, :b)",
        #     expression_attribute_names: {
        #       "#H" => "uuid",
        #       "#R" => "id",
        #       "#B" => "body"
        #     },
        #     expression_attribute_values: {
        #       ":h" => "123456789uuid987654321",
        #       ":r" => 100,
        #       ":b" => "some substring"
        #     }
        #   )
        #
        #   # You can enumerate over your results.
        #   query.each do |r|
        #     puts "UUID: #{r.uuid}\nID: #{r.id}\nBODY: #{r.body}\n"
        #   end
        #
        # @param [Hash] opts options to pass on to the client call to +#query+.
        #   See the documentation above in the AWS SDK for Ruby V3.
        # @return [Aws::Record::ItemCollection] an enumerable collection of the
        #   query result.
        def query(opts)
          query_opts = opts.merge(table_name: table_name)
          ItemCollection.new(:query, query_opts, self, dynamodb_client)
        end

        # This method calls
        # {http://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/DynamoDB/Client.html#scan-instance_method
        # Aws::DynamoDB::Client#scan}, populating the +:table_name+ parameter from the model
        # class, and combining this with the other parameters you provide.
        #
        # @example A scan with a filter expression:
        #   # Example model class
        #   class ExampleTable
        #     include Aws::Record
        #     string_attr  :uuid, hash_key: true
        #     integer_attr :id,   range_key: true
        #     string_attr  :body
        #   end
        #
        #   scan = ExampleTable.scan(
        #     filter_expression: "contains(#B, :b)",
        #     expression_attribute_names: {
        #       "#B" => "body"
        #     },
        #     expression_attribute_values: {
        #       ":b" => "some substring"
        #     }
        #   )
        #
        #   # You can enumerate over your results.
        #   scan.each do |r|
        #     puts "UUID: #{r.uuid}\nID: #{r.id}\nBODY: #{r.body}\n"
        #   end
        #
        # @param [Hash] opts options to pass on to the client call to +#scan+.
        #   See the documentation above in the AWS SDK for Ruby V3.
        # @return [Aws::Record::ItemCollection] an enumerable collection of the
        #   scan result.
        def scan(opts = {})
          scan_opts = opts.merge(table_name: table_name)
          ItemCollection.new(:scan, scan_opts, self, dynamodb_client)
        end

        # This method allows you to build a query using the {Aws::Record::BuildableSearch} DSL.
        #
        # @example Building a simple query:
        #   # Example model class
        #   class ExampleTable
        #     include Aws::Record
        #     string_attr  :uuid, hash_key: true
        #     integer_attr :id,   range_key: true
        #     string_attr  :body
        #   end
        #
        #   q = ExampleTable.build_query.key_expr(
        #         ":uuid = ? AND :id > ?", "smpl-uuid", 100
        #       ).scan_ascending(false).complete!
        #   q.to_a # You can use this like any other query result in aws-record
        def build_query
          BuildableSearch.new(
            operation: :query,
            model: self
          )
        end

        # This method allows you to build a scan using the {Aws::Record::BuildableSearch} DSL.
        #
        # @example Building a simple scan:
        #   # Example model class
        #   class ExampleTable
        #     include Aws::Record
        #     string_attr  :uuid, hash_key: true
        #     integer_attr :id,   range_key: true
        #     string_attr  :body
        #   end
        #
        #   segment_2_scan = ExampleTable.build_scan.filter_expr(
        #     "contains(:body, ?)",
        #     "bacon"
        #   ).scan_ascending(false).parallel_scan(
        #     total_segments: 5,
        #     segment: 2
        #   ).complete!
        #   segment_2_scan.to_a # You can use this like any other query result in aws-record
        def build_scan
          BuildableSearch.new(
            operation: :scan,
            model: self
          )
        end
      end
    end
  end
end

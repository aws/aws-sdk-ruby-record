# Copyright 2015-2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

      def compatible?
        resp = @client.describe_table(table_name: @model_class.table_name)
        _throughput_equal(resp) && _keys_equal(resp) && _ad_superset(resp)
      end

      def exact_match?
        resp = @client.describe_table(table_name: @model_class.table_name)
        _throughput_equal(resp) && _keys_equal(resp) && _ad_equal(resp)
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

      def _throughput_equal(resp)
        expected = resp.table.provisioned_throughput.to_h
        actual = {
          read_capacity_units: @read_capacity_units,
          write_capacity_units: @write_capacity_units
        }
        actual.all? do |k,v|
          expected[k] == v
        end
      end

      def _keys_equal(resp)
        remote_key_schema = resp.table.key_schema.map { |i| i.to_h }
        _array_unsorted_eql(remote_key_schema, _key_schema)
      end

      def _ad_equal(resp)
        remote_ad = resp.table.attribute_definitions.map { |i| i.to_h }
        _array_unsorted_eql(remote_ad, _attribute_definitions)
      end

      def _ad_superset(resp)
        remote_ad = resp.table.attribute_definitions.map { |i| i.to_h }
        _attribute_definitions.all? do |attribute_definition|
          remote_ad.include?(attribute_definition)
        end
      end

      def _array_unsorted_eql(a, b)
        a.all? { |x| b.include?(x) } && b.all? { |x| a.include?(x) }
      end

    end
  end
end

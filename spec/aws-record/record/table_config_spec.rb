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

require 'spec_helper'

module Aws
  module Record
    describe TableConfig do

      let(:api_requests) { [] }

      def configure_test_client(client)
        requests = api_requests
        client.handle do |context|
          requests << context.params
          @handler.call(context)
        end
        client
      end

      it 'accepts a minimal set of table configuration inputs' do
        cfg = TableConfig.define do |t|
          t.model_class(TestModel)
          t.read_capacity_units(1)
          t.write_capacity_units(1)
          t.client_options(stub_responses: true)
        end
      end

      describe "#migrate!" do
        it 'will attempt to create the remote table if it does not exist' do
          cfg = TableConfig.define do |t|
            t.model_class(TestModel)
            t.read_capacity_units(1)
            t.write_capacity_units(1)
            t.client_options(stub_responses: true)
          end
          stub_client = configure_test_client(cfg.client)
          stub_client.stub_responses(
            :describe_table,
            { table: { table_status: "ACTIVE" } }
          )
          cfg.migrate!
          expect(api_requests[0]).to eq(
            table_name: "TestModel",
            provisioned_throughput:
            {
              read_capacity_units: 1,
              write_capacity_units: 1
            },
            key_schema: [
              {
                attribute_name: "hk",
                key_type: "HASH"
              },
              {
                attribute_name: "rk",
                key_type: "RANGE"
              }
            ],
            attribute_definitions: [
              {
                attribute_name: "hk",
                attribute_type: "S"
              },
              {
                attribute_name: "rk",
                attribute_type: "S"
              }
            ]
          )
        end
      end

    end
  end
end

class TestModel
  include Aws::Record

  string_attr :hk, hash_key: true
  string_attr :rk, range_key: true
end

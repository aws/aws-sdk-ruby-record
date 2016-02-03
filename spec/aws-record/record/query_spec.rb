# Copyright 2015-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
    describe "Query" do

      let(:klass) do
        Class.new do
          include(Aws::Record)
          set_table_name("TestTable")
          integer_attr(:id, hash_key: true)
          date_attr(:date, range_key: true)
          string_attr(:body)
        end
      end

      let(:api_requests) { [] }

      let(:stub_client) do
        requests = api_requests
        client = Aws::DynamoDB::Client.new(stub_responses: true)
        client.handle do |context|
          requests << context.params
          @handler.call(context)
        end
        client
      end

      describe "#query" do
        it 'can pass on a manually constructed query to the client' do
          stub_client.stub_responses(:query,
            {
              items: [
                {
                  "id" => 1,
                  "date" => "2016-01-25",
                  "body" => "Item 1"
                },
                {
                  "id" => 1,
                  "date" => "2016-01-26",
                  "body" => "Item 2"
                }
              ],
              count: 2,
              scanned_count: 2,
              last_evaluated_key: nil
            })
          klass.configure_client(client: stub_client)
          query_opts = {
            key_conditions: {
              id: {
                attribute_value_list: [1],
                comparison_operator: "EQ"
              },
              date: {
                attribute_value_list: ["2016-01-01"],
                comparison_operator: "GT"
              }
            }
          }
          ret = klass.query(query_opts).to_a
          expect(api_requests).to eq([{
            table_name: "TestTable",
            key_conditions: {
              "id" => {
                attribute_value_list: [{ n: "1" }],
                comparison_operator: "EQ"
              },
              "date" => {
                attribute_value_list: [{ s: "2016-01-01" }],
                comparison_operator: "GT"
              }
            }
          }])
        end
      end

      describe "#scan" do
        it 'can pass on a manually constructed scan to the client' do
          stub_client.stub_responses(:scan,
            {
              items: [
                {
                  "id" => 1,
                  "date" => "2016-01-25",
                  "body" => "Item 1"
                },
                {
                  "id" => 1,
                  "date" => "2016-01-26",
                  "body" => "Item 2"
                }
              ],
              count: 2,
              scanned_count: 2,
              last_evaluated_key: nil
            })
          klass.configure_client(client: stub_client)
          ret = klass.scan.to_a
          expect(api_requests).to eq([{ table_name: "TestTable" }])
        end
      end

    end
  end
end

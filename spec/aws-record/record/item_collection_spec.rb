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
    describe ItemCollection do

      let(:model) do
        Class.new do
          include(Aws::Record)
          set_table_name("TestTable")
          integer_attr(:id, hash_key: true)
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

      describe "#each" do
        let(:truncated_resp) do
          {
            items: [
              { "id" => 1 },
              { "id" => 2 },
              { "id" => 3 }
            ],
            count: 3,
            last_evaluated_key: { "id" => { n: "3" } }
          }
        end

        let(:non_truncated_resp) do
          {
            items: [
              { "id" => 4 },
              { "id" => 5 }
            ],
            count: 2,
            last_evaluated_key: nil
          }
        end

        it "correctly iterates through a paginated response" do
          stub_client.stub_responses(:scan, truncated_resp, non_truncated_resp)
          c = ItemCollection.new(
            :scan,
            { table_name: "TestTable" },
            model,
            stub_client
          )
          expected = [1,2,3,4,5]
          actual = c.map { |item| item.id }
          expect(actual).to eq(expected)
        end
      end

      describe "#empty?" do
        let(:resp_full) do
          {
            items: [
              { "id" => 1 },
              { "id" => 2 },
              { "id" => 3 }
            ],
            count: 3
          }
        end

        let(:resp_empty) do
          {
            items: [],
            count: 0
          }
        end


        it "is not empty" do
          stub_client.stub_responses(:scan, resp_full)
          c = ItemCollection.new(
            :scan,
            { table_name: "TestTable" },
            model,
            stub_client
          )
          expect(c.empty?).to be_falsy
        end

        it "is empty" do
          stub_client.stub_responses(:scan, resp_empty)
          c = ItemCollection.new(
            :scan,
            { table_name: "TestTable" },
            model,
            stub_client
          )
          expect(c.empty?).to be_truthy
        end
      end

    end
  end
end

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

      describe "#page" do
        it "provides an array of items from a single client call" do
          stub_client.stub_responses(:scan, truncated_resp)
          c = ItemCollection.new(
            :scan,
            { table_name: "TestTable" },
            model,
            stub_client
          )
          actual = c.page
          expect(actual.size).to eq(3)
          actual_ids = actual.map { |a| a.id }
          expect(actual_ids).to eq([1,2,3])
          expect(c.last_evaluated_key).to eq({"id" => { "n" => "3" }})
        end
      end

      describe "#new_record" do
        it "marks a new record as being new" do
          record = model.new
          expect(record.new_record?).to be(true)
          expect(record.destroyed?).to be(false)
        end

        it "marks records fetched from a client call as not being new" do
          stub_client.stub_responses(:scan, non_truncated_resp)
          c = ItemCollection.new(
            :scan,
            { table_name: "TestTable" },
            model,
            stub_client
          )

          c.each do |record|
            expect(record.new_record?).to be(false)
            expect(record.destroyed?).to be(false)
          end
        end
      end

      describe "#last_evaluated_key" do
        it "points you to the client response pagination value if present" do
          stub_client.stub_responses(:scan, truncated_resp)
          c = ItemCollection.new(
            :scan,
            { table_name: "TestTable" },
            model,
            stub_client
          )
          c.take(2) # Trigger the "call"
          expect(c.last_evaluated_key).to eq({"id" => { "n" => "3" }})
        end

        it "provides a nil pagination value if no pages remain" do
          stub_client.stub_responses(:scan, non_truncated_resp)
          c = ItemCollection.new(
            :scan,
            { table_name: "TestTable" },
            model,
            stub_client
          )
          c.take(2) # Trigger the "call"
          expect(c.last_evaluated_key).to be_nil
        end

        it "correctly provides the most recent pagination key" do
          stub_client.stub_responses(:scan, truncated_resp, non_truncated_resp)
          c = ItemCollection.new(
            :scan,
            { table_name: "TestTable" },
            model,
            stub_client
          )
          c.take(4) # Trigger the "call" and the second "page"
          expect(c.last_evaluated_key).to be_nil
        end

        it "gathers evaluation keys from #page as well" do
          stub_client.stub_responses(:scan, truncated_resp)
          c = ItemCollection.new(
            :scan,
            { table_name: "TestTable" },
            model,
            stub_client
          )
          c.page
          expect(c.last_evaluated_key).to eq({"id" => { "n" => "3" }})
          stub_client.stub_responses(:scan, non_truncated_resp)
          c = ItemCollection.new(
            :scan,
            { table_name: "TestTable" },
            model,
            stub_client
          )
          c.page
          expect(c.last_evaluated_key).to be_nil
        end
      end

      describe "#each" do

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

        let(:truncated_empty) do
          {
            items: [],
            count: 0,
            last_evaluated_key: { "id" => { n: "3" } }
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

        it "handles initial pages being empty" do
          # Scans with limit fields may return empty pages, while values still
          # exist.
          stub_client.stub_responses(:scan, truncated_empty, resp_full)
          c = ItemCollection.new(
            :scan,
            { table_name: "TestTable", limit: 3 },
            model,
            stub_client
          )
          expect(c.empty?).to be_falsy
        end

        it "handles final pages being empty" do
          # LastEvaluatedKey being present does not guarantee additional data is
          # coming, so make sure we handle a final empty page.
          stub_client.stub_responses(:scan, truncated_resp, resp_empty)
          c = ItemCollection.new(
            :scan,
            { table_name: "TestTable" },
            model,
            stub_client
          )
          expect(c.empty?).to be_falsy
        end
      end

    end
  end
end

# Copyright 2015-2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
    describe Transactions do
      let(:stub_client) do
        Aws::DynamoDB::Client.new(stub_responses: true)
      end

      let(:table_one) do
        Class.new do
          include(Aws::Record)
          set_table_name("TableOne")
          integer_attr(:id, hash_key: true)
          string_attr(:range, range_key: true)
          string_attr(:body)
        end
      end

      let(:table_two) do
        Class.new do
          include(Aws::Record)
          set_table_name("TableTwo")
          string_attr(:uuid, hash_key: true)
          string_attr(:body)
        end
      end

      describe "#transact_find" do
        it 'uses tfind_opts to construct a request and returns modeled items' do
          stub_client.stub_responses(:transact_get_items,
            {
              responses: [
                {item: {
                  'id' => 1, 'range' => 'a', 'body' => 'One'
                }},
                {item: {
                  'uuid' => 'foo', 'body' => 'Two'
                }},
                {item: {
                  'id' => 2, 'range' => 'b', 'body' => 'Three'
                }}
              ]
            }
          )
          Aws::Record::Transactions.configure_client(client: stub_client)
          items = Aws::Record::Transactions.transact_find(
            transact_items: [
              table_one.tfind_opts(key: {id: 1, range: "a"}),
              table_two.tfind_opts(key: {uuid: "foo"}),
              table_one.tfind_opts(key: {id: 2, range: "b"})
            ]
          )
          expect(items.responses.size).to eq(3)
          expect(items.responses[0].class).to eq(table_one)
          expect(items.responses[1].class).to eq(table_two)
          expect(items.responses[2].class).to eq(table_one)
          expect(items.responses[0].body).to eq('One')
          expect(items.responses[1].body).to eq('Two')
          expect(items.responses[2].body).to eq('Three')
          expect(items.missing_items.size).to eq(0)
        end

        it 'handles and reports missing keys' do
          stub_client.stub_responses(:transact_get_items,
            {
              responses: [
                {item: {
                  'id' => 1, 'range' => 'a', 'body' => 'One'
                }},
                {item: nil},
                {item: {
                  'id' => 2, 'range' => 'b', 'body' => 'Three'
                }}
              ]
            }
          )
          Aws::Record::Transactions.configure_client(client: stub_client)
          items = Aws::Record::Transactions.transact_find(
            transact_items: [
              table_one.tfind_opts(key: {id: 1, range: "a"}),
              table_two.tfind_opts(key: {uuid: "foo"}),
              table_one.tfind_opts(key: {id: 2, range: "b"})
            ]
          )
          expect(items.responses.size).to eq(3)
          expect(items.responses[1]).to be_nil
          expect(items.responses[0].class).to eq(table_one)
          expect(items.responses[2].class).to eq(table_one)
          expect(items.responses[0].body).to eq('One')
          expect(items.responses[2].body).to eq('Three')
          expect(items.missing_items.size).to eq(1)
          expect(items.missing_items[0]).to eq({
            model_class: table_two,
            key: {"uuid" => "foo"}
          })
        end
      end

      describe "#transact_write" do
        
      end
    end
  end
end

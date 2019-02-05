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
          string_attr(:has_default, default_value: "Lorem ipsum.")
        end
      end

      let(:table_two) do
        Class.new do
          include(Aws::Record)
          set_table_name("TableTwo")
          string_attr(:uuid, hash_key: true)
          string_attr(:body)
          string_attr(:has_default, default_value: "Lorem ipsum.")
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

        it 'raises when tfind_opts is missing a key' do
          expect {
            Aws::Record::Transactions.transact_find(
              transact_items: [
                table_one.tfind_opts(key: {range: "a"}),
                table_two.tfind_opts(key: {uuid: "foo"}),
                table_one.tfind_opts(key: {id: 2, range: "b"})
              ]
            )
          }.to raise_error(Aws::Record::Errors::KeyMissing)
        end
      end

      describe "#transact_write" do

        it 'supports the basic update transaction types' do
          Aws::Record::Transactions.configure_client(client: stub_client)
          put_item = table_one.new(id: 1, range: 'a')
          update_item = table_two.new(uuid: "foo")
          update_item.clean! # like we got it from #find
          update_item.body = "Content"
          delete_item = table_one.new(id: 2, range: 'b')
          delete_item.clean! # like we got it from #find
          Aws::Record::Transactions.transact_write(
            transact_items: [
              { put: put_item },
              { update: update_item },
              { delete: delete_item }
            ]
          )
          expect(stub_client.api_requests.size).to eq(1)
          request_params = stub_client.api_requests.first[:params]
          expect(request_params[:transact_items]).to eq([
            {
              put: {
                table_name: "TableOne",
                item: {
                  "has_default"=>{s: "Lorem ipsum."},
                  "id"=>{n: "1"},
                  "range"=>{s: "a"}
                }
              }
            },
            {
              update: {
                table_name: "TableTwo",
                key: {"uuid"=>{s: "foo"}},
                update_expression: "SET #UE_A = :ue_a",
                expression_attribute_names: {"#UE_A" => "body"},
                expression_attribute_values: {":ue_a" => {s: "Content"}}
              }
            },
            {
              delete: {
                table_name: "TableOne",
                key: {
                  "id" => {n: "2"},
                  "range"=>{s: "b"}
                }
              }
            }
          ])
        end

        it 'supports manually defined check operations' do
          Aws::Record::Transactions.configure_client(client: stub_client)
          check_exp = table_one.transact_check_expression(
            key: { id: 10, range: 'z' },
            condition_expression: "size(#T) <= :v",
            expression_attribute_names: {
              "#T" => "body"
            },
            expression_attribute_values: {
              ":v" => 1024
            }
          )
          put_item = table_one.new(id: 1, range: 'a')
          Aws::Record::Transactions.transact_write(
            transact_items: [
              { check: check_exp },
              { put: put_item }
            ]
          )
          expect(stub_client.api_requests.size).to eq(1)
          request_params = stub_client.api_requests.first[:params]
          expect(request_params[:transact_items]).to eq([
            {
              condition_check: {
                key: {
                  "id" => {n: '10'},
                  "range" => {s: 'z'}
                },
                table_name: "TableOne",
                condition_expression: "size(#T) <= :v",
                expression_attribute_names: {
                  "#T" => "body"
                },
                expression_attribute_values: {
                  ":v" => {n: '1024'}
                }
              }
            },
            {
              put: {
                table_name: "TableOne",
                item: {
                  "has_default"=>{s: "Lorem ipsum."},
                  "id"=>{n: "1"},
                  "range"=>{s: "a"}
                }
              }
            }
          ])
        end

        it 'supports transactional save as an update or safe put' do
          Aws::Record::Transactions.configure_client(client: stub_client)
          put_item = table_one.new(id: 1, range: 'a')
          update_item = table_two.new(uuid: "foo")
          update_item.clean! # like we got it from #find
          update_item.body = "Content"
          Aws::Record::Transactions.transact_write(
            transact_items: [
              { save: put_item },
              { save: update_item }
            ]
          )
          expect(stub_client.api_requests.size).to eq(1)
          request_params = stub_client.api_requests.first[:params]
          expect(request_params[:transact_items]).to eq([
            {
              put: {
                table_name: "TableOne",
                item: {
                  "has_default"=>{s: "Lorem ipsum."},
                  "id"=>{n: "1"},
                  "range"=>{s: "a"}
                },
                condition_expression: "attribute_not_exists(#H) and attribute_not_exists(#R)",
                expression_attribute_names: {
                  "#H"=>"id",
                  "#R"=>"range"
                }
              }
            },
            {
              update: {
                table_name: "TableTwo",
                key: {"uuid"=>{s: "foo"}},
                update_expression: "SET #UE_A = :ue_a",
                expression_attribute_names: {"#UE_A" => "body"},
                expression_attribute_values: {":ue_a" => {s: "Content"}}
              }
            }
          ])
        end

        it 'supports additional options per transaction' do
          Aws::Record::Transactions.configure_client(client: stub_client)
          put_item = table_one.new(id: 1, range: 'a')
          update_item = table_two.new(uuid: "foo")
          update_item.clean! # like we got it from #find
          update_item.body = "Content"
          delete_item = table_one.new(id: 2, range: 'b')
          delete_item.clean! # like we got it from #find
          save_item = table_one.new(id: 3, range: 'c')
          Aws::Record::Transactions.transact_write(
            transact_items: [
              {
                put: put_item,
                return_values_on_condition_check_failure: "ALL_OLD"
              },
              {
                update: update_item,
                return_values_on_condition_check_failure: "ALL_OLD"
              },
              {
                delete: delete_item,
                return_values_on_condition_check_failure: "ALL_OLD"
              },
              {
                save: save_item,
                return_values_on_condition_check_failure: "ALL_OLD"
              }
            ]
          )
          expect(stub_client.api_requests.size).to eq(1)
          request_params = stub_client.api_requests.first[:params]
          expect(request_params[:transact_items]).to eq([
            {
              put: {
                table_name: "TableOne",
                item: {
                  "has_default"=>{s: "Lorem ipsum."},
                  "id"=>{n: "1"},
                  "range"=>{s: "a"}
                },
                return_values_on_condition_check_failure: "ALL_OLD"
              }
            },
            {
              update: {
                table_name: "TableTwo",
                key: {"uuid"=>{s: "foo"}},
                update_expression: "SET #UE_A = :ue_a",
                expression_attribute_names: {"#UE_A" => "body"},
                expression_attribute_values: {":ue_a" => {s: "Content"}},
                return_values_on_condition_check_failure: "ALL_OLD"
              }
            },
            {
              delete: {
                table_name: "TableOne",
                key: {
                  "id" => {n: "2"},
                  "range"=>{s: "b"}
                },
                return_values_on_condition_check_failure: "ALL_OLD"
              }
            },
            {
              put: {
                table_name: "TableOne",
                item: {
                  "has_default"=>{s: "Lorem ipsum."},
                  "id"=>{n: "3"},
                  "range"=>{s: "c"}
                },
                condition_expression: "attribute_not_exists(#H) and attribute_not_exists(#R)",
                expression_attribute_names: {
                  "#H"=>"id",
                  "#R"=>"range"
                },
                return_values_on_condition_check_failure: "ALL_OLD"
              }
            }
          ])
        end

        it 'can combine expression attributes for update' do
          Aws::Record::Transactions.configure_client(client: stub_client)
          update_item = table_two.new(uuid: "foo")
          update_item.clean! # like we got it from #find
          update_item.body = "Content"
          save_item = table_two.new(uuid: "bar")
          save_item.clean! # like we got it from #find
          save_item.body = "Content"
          Aws::Record::Transactions.transact_write(
            transact_items: [
              {
                update: update_item,
                condition_expression: "size(#T) <= :v",
                expression_attribute_names: {
                  "#T" => "body"
                },
                expression_attribute_values: {
                  ":v" => 1024
                },
                return_values_on_condition_check_failure: "ALL_OLD"
              },
              {
                save: save_item,
                condition_expression: "size(#T) <= :v",
                expression_attribute_names: {
                  "#T" => "body"
                },
                expression_attribute_values: {
                  ":v" => 1024
                },
                return_values_on_condition_check_failure: "ALL_OLD"
              }
            ]
          )
          expect(stub_client.api_requests.size).to eq(1)
          request_params = stub_client.api_requests.first[:params]
          expect(request_params[:transact_items]).to eq([
            {
              update: {
                table_name: "TableTwo",
                key: {"uuid"=>{s: "foo"}},
                update_expression: "SET #UE_A = :ue_a",
                condition_expression: "size(#T) <= :v",
                expression_attribute_names: {
                  "#UE_A" => "body",
                  "#T" => "body"
                },
                expression_attribute_values: {
                  ":ue_a" => {s: "Content"},
                  ":v" => {n: '1024'}
                },
                return_values_on_condition_check_failure: "ALL_OLD"
              }
            },
            {
              update: {
                table_name: "TableTwo",
                key: {"uuid"=>{s: "bar"}},
                update_expression: "SET #UE_A = :ue_a",
                condition_expression: "size(#T) <= :v",
                expression_attribute_names: {
                  "#UE_A" => "body",
                  "#T" => "body"
                },
                expression_attribute_values: {
                  ":ue_a" => {s: "Content"},
                  ":v" => {n: '1024'}
                },
                return_values_on_condition_check_failure: "ALL_OLD"
              }
            }
          ])
        end

        # Still deciding if this makes sense or if we need to design a
        # different out
        it 'can combine expression attributes for save as safe put'

      end
    end
  end
end

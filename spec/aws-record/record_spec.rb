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
  describe 'Record' do

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

    describe '#table_name' do
      it 'should have an implied table name from the class name' do
        ::UnitTestModel = Class.new do
          include(Aws::Record)
        end
        expect(UnitTestModel.table_name).to eq("UnitTestModel")
      end

      it 'should allow a custom table name to be specified' do
        expected = "ExpectedTableName"
        ::UnitTestModelTwo = Class.new do
          include(Aws::Record)
          set_table_name(expected)
        end
        expect(::UnitTestModelTwo.table_name).to eq(expected)
      end
    end

    describe '#provisioned_throughput' do
      let(:model) {
        Class.new do
          include(Aws::Record)
          set_table_name("TestTable")
        end
      }

      it 'should fetch the provisioned throughput for the table on request' do
        stub_client.stub_responses(:describe_table,
          {
            table: {
              provisioned_throughput: {
                read_capacity_units: 25,
                write_capacity_units: 10
              }
            }
          })
        model.configure_client(client: stub_client)
        resp = model.provisioned_throughput
        expect(api_requests).to eq([{
          table_name: "TestTable"
        }])
        expect(resp).to eq({
          read_capacity_units: 25,
          write_capacity_units: 10
        })
      end

      it 'should raise a TableDoesNotExist error if the table does not exist' do
        stub_client.stub_responses(:describe_table, 'ResourceNotFoundException')
        model.configure_client(client: stub_client)
        expect { model.provisioned_throughput }.to raise_error(
          Record::Errors::TableDoesNotExist
        )
      end
    end

    describe '#table_exists' do
      let(:model) {
        Class.new do
          include(Aws::Record)
          set_table_name("TestTable")
        end
      }

      it 'can check if the table exists' do
        stub_client.stub_responses(:describe_table,
          {
            table: { table_status: "ACTIVE" }
          })
        model.configure_client(client: stub_client)
        expect(model.table_exists?).to eq(true)
      end

      it 'will not recognize a table as existing if it is not active' do
        stub_client.stub_responses(:describe_table,
          {
            table: { table_status: "CREATING" }
          })
        model.configure_client(client: stub_client)
        expect(model.table_exists?).to eq(false)
      end

      it 'will answer false to #table_exists? if the table does not exist in DynamoDB' do
        stub_client.stub_responses(:describe_table, 'ResourceNotFoundException')
        model.configure_client(client: stub_client)
        expect(model.table_exists?).to eq(false)
      end

    end
  end
end

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


  end
end

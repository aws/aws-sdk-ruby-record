require 'spec_helper'

module Aws
  module Record
    describe TableMigration do

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

      it 'only accepts Aws::Record models' do
        expect { TableMigration.new(Class.new) }.to raise_error(
          Errors::InvalidModel, "Table models must include Aws::Record"
        )
      end

      it 'requires that models contain a valid key' do
        model = Class.new do
          include(Aws::Record)
        end
        expect { TableMigration.new(model) }.to raise_error(
          Errors::InvalidModel, "Table models must include a hash key"
        )
      end

      context "Migration Operations" do

        let(:klass) do
          Class.new do
            include(Aws::Record)
            set_table_name("TestTable")
            integer_attr(:id, hash_key: true)
            date_attr(:date, range_key: true)
          end
        end

        let(:migration) do
          TableMigration.new(klass)
        end

        context "#create!" do
          it 'calls #create_table on a client when #create! is called' do
            create_opts = {
              provisioned_throughput: {
                read_capacity_units: 5,
                write_capacity_units: 2
              }
            }
            migration.client = stub_client
            migration.create!(create_opts)
            expect(api_requests).to eq([{
              table_name: "TestTable",
              attribute_definitions: [
                {
                  attribute_name: "id",
                  attribute_type: "N"
                },
                {
                  attribute_name: "date",
                  attribute_type: "S"
                }
              ],
              key_schema: [
                {
                  attribute_name: "id",
                  key_type: "HASH"
                },
                {
                  attribute_name: "date",
                  key_type: "RANGE"
                }
              ],
              provisioned_throughput: {
                read_capacity_units: 5,
                write_capacity_units: 2
              }
            }])
          end
        end

        context "#delete!" do
          it 'calls #delete_table on a client when #delete! is called' do
            migration.client = stub_client
            migration.delete!
            expect(api_requests).to eq([{
              table_name: "TestTable"
            }])
          end

          it 'throws TableDoesNotExist when table did not exist at call time' do
            stub_client.stub_responses(:delete_table,
              'ResourceNotFoundException')
            migration.client = stub_client
            expect { migration.delete! }.to raise_error(
              Errors::TableDoesNotExist
            )
          end
        end

        context "#update!" do
          it 'calles #update_table on a client when #update! is called' do
            update_opts = {
              provisioned_throughput: {
                read_capacity_units: 4,
                write_capacity_units: 3
              }
            }
            migration.client = stub_client
            migration.update!(update_opts)
            expect(api_requests).to eq([{
              table_name: "TestTable",
              provisioned_throughput: {
                read_capacity_units: 4,
                write_capacity_units: 3
              }
            }])
          end

          it 'throws TableDoesNotExist when table did not exist at call time' do
            stub_client.stub_responses(:update_table,
              'ResourceNotFoundException')
            migration.client = stub_client
            expect { migration.update!({}) }.to raise_error(
              Errors::TableDoesNotExist
            )
          end
        end

      end
    end
  end
end

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

      context 'client' do
        let(:model_stub_client) { Aws::DynamoDB::Client.new(stub_responses: true) }
        let(:model) do
          model = Class.new do
            include(Aws::Record)
            set_table_name("TestTable")
            integer_attr(:id, hash_key: true)
          end
          model.configure_client client: model_stub_client
          model
        end

        it 'uses client given as option with the highest priority' do
          expect(TableMigration.new(model, client: stub_client).client).to eq stub_client
        end

        it 'uses client set to model' do
          expect(TableMigration.new(model).client).to eq model_stub_client
        end
      end

      context "Migration Operations" do

        let(:klass) do
          Class.new do
            include(Aws::Record)
            set_table_name("TestTable")
            integer_attr(:id, hash_key: true)
            date_attr(:date, range_key: true, database_attribute_name: "datekey")
            string_attr(:lsi)
            string_attr(:gsi_partition)
            string_attr(:gsi_sort)
          end
        end

        let(:migration) do
          TableMigration.new(klass, client: stub_client)
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
                  attribute_name: "datekey",
                  attribute_type: "S"
                }
              ],
              key_schema: [
                {
                  attribute_name: "id",
                  key_type: "HASH"
                },
                {
                  attribute_name: "datekey",
                  key_type: "RANGE"
                }
              ],
              provisioned_throughput: {
                read_capacity_units: 5,
                write_capacity_units: 2
              }
            }])
          end

          it 'accepts models with a local secondary index' do
            create_opts = {
              provisioned_throughput: {
                read_capacity_units: 5,
                write_capacity_units: 2
              }
            }
            klass.local_secondary_index(
              :test_lsi,
              range_key: :lsi,
              projection: {
                projection_type: "ALL"
              }
            )
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
                  attribute_name: "datekey",
                  attribute_type: "S"
                },
                {
                  attribute_name: "lsi",
                  attribute_type: "S"
                }
              ],
              key_schema: [
                {
                  attribute_name: "id",
                  key_type: "HASH"
                },
                {
                  attribute_name: "datekey",
                  key_type: "RANGE"
                }
              ],
              local_secondary_indexes: [{
                index_name: "test_lsi",
                key_schema: [
                  {
                    attribute_name: "id",
                    key_type: "HASH"
                  },
                  {
                    attribute_name: "lsi",
                    key_type: "RANGE"
                  }
                ],
                projection: {
                  projection_type: "ALL"
                }
              }],
              provisioned_throughput: {
                read_capacity_units: 5,
                write_capacity_units: 2
              }
            }])
          end

          it 'accepts models with a global secondary index' do
            create_opts = {
              provisioned_throughput: {
                read_capacity_units: 5,
                write_capacity_units: 2
              },
              global_secondary_index_throughput: {
                test_gsi: {
                  read_capacity_units: 3,
                  write_capacity_units: 1
                }
              }
            }
            klass.global_secondary_index(
              :test_gsi,
              hash_key: :gsi_partition,
              range_key: :gsi_sort,
              projection: {
                projection_type: "ALL"
              }
            )
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
                  attribute_name: "datekey",
                  attribute_type: "S"
                },
                {
                  attribute_name: "gsi_partition",
                  attribute_type: "S"
                },
                {
                  attribute_name: "gsi_sort",
                  attribute_type: "S"
                }
              ],
              key_schema: [
                {
                  attribute_name: "id",
                  key_type: "HASH"
                },
                {
                  attribute_name: "datekey",
                  key_type: "RANGE"
                }
              ],
              global_secondary_indexes: [{
                index_name: "test_gsi",
                key_schema: [
                  {
                    attribute_name: "gsi_partition",
                    key_type: "HASH"
                  },
                  {
                    attribute_name: "gsi_sort",
                    key_type: "RANGE"
                  }
                ],
                projection: {
                  projection_type: "ALL"
                },
                provisioned_throughput: {
                  read_capacity_units: 3,
                  write_capacity_units: 1
                }
              }],
              provisioned_throughput: {
                read_capacity_units: 5,
                write_capacity_units: 2
              }
            }])
          end

          it 'required global secondary index throughput to be provided' do
            create_opts = {
              provisioned_throughput: {
                read_capacity_units: 5,
                write_capacity_units: 2
              }
            }
            klass.global_secondary_index(
              :test_gsi,
              hash_key: :gsi_partition,
              range_key: :gsi_sort,
              projection: {
                projection_type: "ALL"
              }
            )
            migration.client = stub_client
            expect { migration.create!(create_opts) }.to raise_error(
              ArgumentError
            )
            expect(api_requests).to eq([])
          end

          it 'requires global secondary index throughput to be defined for each index' do
            create_opts = {
              provisioned_throughput: {
                read_capacity_units: 5,
                write_capacity_units: 2
              },
              global_secondary_index_throughput: {
                test_gsi: {
                  read_capacity_units: 1,
                  write_capacity_units: 1
                }
              }
            }
            klass.global_secondary_index(
              :test_gsi,
              hash_key: :gsi_partition,
              range_key: :gsi_sort,
              projection: {
                projection_type: "ALL"
              }
            )
            klass.global_secondary_index(
              :fail_on,
              hash_key: :gsi_partition,
              range_key: :gsi_sort,
              projection: {
                projection_type: "ALL"
              }
            )
            migration.client = stub_client
            expect { migration.create!(create_opts) }.to raise_error(
              ArgumentError
            )
            expect(api_requests).to eq([])
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

        context '#wait_until_available' do
          it "can check on the table's availability status" do
            stub_client.stub_responses(:describe_table,
              {
                table: { table_status: "ACTIVE" }
              })
            migration.client = stub_client
            expect(migration.wait_until_available).not_to eq(nil)
          end
        end

      end
    end
  end
end

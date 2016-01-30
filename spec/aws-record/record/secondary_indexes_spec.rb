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
    describe "SecondaryIndexes" do

      let(:klass) do
        Class.new do
          include(Aws::Record)
          set_table_name("TestTable")
          integer_attr(:forum_id, hash_key: true)
          integer_attr(:post_id, range_key: true)
          string_attr(:forum_name)
          string_attr(:post_title)
          integer_attr(:author_id, database_attribute_name: 'a_id')
          string_attr(:author_name)
          string_attr(:post_body)
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

      context "Local Secondary Index" do

        describe "#local_secondary_index" do
          it 'allows you to define a local secondary index on the model' do
            klass.local_secondary_index(
              :title,
              range_key: :post_title,
              projection: {
                projection_type: "ALL"
              }
            )
            expect(klass.local_secondary_indexes[:title]).not_to eq(nil)
          end

          it 'requires that a range key is provided' do
            expect {
              klass.local_secondary_index(
                :fail,
                projection: { projection_type: "ALL" }
              )
            }.to raise_error(ArgumentError)
          end

          it 'requires use of an attribute that exists in the model' do
            expect {
              klass.local_secondary_index(
                :fail,
                range_key: :missingno,
                projection: { projection_type: "ALL" }
              )
            }.to raise_error(ArgumentError)
          end
        end

        describe "#local_secondary_indexes_for_migration" do
          it 'correctly translates database names for migration' do
            klass.local_secondary_index(
              :author,
              range_key: :author_id,
              projection: {
                projection_type: "ALL"
              }
            )
            migration = klass.local_secondary_indexes_for_migration
            expect(migration.size).to eq(1)
            expect(migration.first).to eq({
              index_name: :author,
              key_schema: [
                { key_type: "HASH", attribute_name: "forum_id" },
                { key_type: "RANGE", attribute_name: "a_id" }
              ],
              projection: { projection_type: "ALL" }
            })
          end
        end

      end

    end
  end
end

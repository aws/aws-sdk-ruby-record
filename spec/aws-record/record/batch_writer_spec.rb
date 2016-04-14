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
    describe BatchWriter do

      let(:klass) do
        Class.new do
          include(Aws::Record)
          set_table_name("TestTable")
          integer_attr(:id, hash_key: true)
          string_attr(:body)
        end
      end

      let(:batch_writer) do
        klass.configure_client(client: stub_client)
        klass.batch_writer(valid_items)
      end

      let(:invalid_batch_writer) do
        klass.configure_client(client: stub_client)
        klass.batch_writer(invalid_items)
      end

      let(:batch_writer_server_err) do
        err_client = Aws::DynamoDB::Client.new(stub_responses: true)
        err_client.stub_responses(
          :batch_write_item,
          error
        )
        klass.configure_client(client: err_client)
        klass.batch_writer(valid_items)
      end

      let(:error) { 'ProvisionedThroughputExceededException' }

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

      let(:valid_items) do
        k1 = klass.new
        k1.id = 1
        k2 = klass.new
        k2.id = 2
        k3 = klass.new
        k3.id = 3
        [k1, k2, k3]
      end

      let(:invalid_items) { [klass.new, klass.new, klass.new] }

      describe "#pending" do
        it "returns true before save is called" do
          expect(batch_writer.pending?).to be_truthy
        end

        it "returns false after save is called" do
          batch_writer.save
          expect(batch_writer.pending?).to be_falsy
        end
      end

      describe '#unprocessed_items' do
        it "is empty before save" do
          expect(batch_writer.unprocessed_items).to be_empty
        end

        it "is empty after successful save" do
          batch_writer.save
          expect(batch_writer.unprocessed_items).to be_empty
        end

        it "is empty on failure to validate item in array" do
          invalid_batch_writer.save
          expect(batch_writer.unprocessed_items).to be_empty
        end

        it "is populated on provisioned throughput error" do
          batch_writer_server_err.save
          expect(batch_writer_server_err.unprocessed_items).not_to be_empty
        end
      end

      describe '#error?' do
        it 'is false before save' do
          expect(batch_writer.error?).to be_falsy
        end

        it 'is true when invalid items attempt to save' do
          invalid_batch_writer.save
          expect(invalid_batch_writer.error?).to be_truthy
        end

        it 'is true on provisioned throughput error' do
          batch_writer_server_err.save
          expect(batch_writer_server_err.error?).to be_truthy
        end
      end

      describe '#valid?' do
        it 'is false before save' do
          expect(batch_writer.valid?).to be_falsy
        end

        it 'is false when invalid items attempt to save' do
          invalid_batch_writer.save
          expect(invalid_batch_writer.valid?).to be_falsy
        end

        it 'is false on provisioned throughput error' do
          batch_writer_server_err.save
          expect(batch_writer_server_err.valid?).to be_falsy
        end

        it 'is true on success' do
          batch_writer.save
          expect(batch_writer.valid?).to be_truthy
        end
      end

      describe '#errors' do
        it "is empty before save" do
          expect(batch_writer.unprocessed_items).to be_empty
        end

        it "is empty after successful save" do
          batch_writer.save
          expect(batch_writer.unprocessed_items).to be_empty
        end

        it "is populated on failure to validate item in array" do
          invalid_batch_writer.save
          expect(invalid_batch_writer.unprocessed_items).not_to be_empty
        end

        it "is populated on provisioned throughput error" do
          batch_writer_server_err.save
          expect(batch_writer_server_err.unprocessed_items).not_to be_empty
        end
      end

      describe '#save' do
        it 'saves items to DynamoDB' do
          batch_writer.save
          expect(api_requests).to eq([{
            table_name: "TestTable",
            item: {
              "id" => { n: "1" },
            }
          }])
        end
      end

    end
  end
end
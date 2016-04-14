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
    describe Batch do

      let(:klass) do
        Class.new do
          include(Aws::Record)
          set_table_name("TestTable")
          integer_attr(:id, hash_key: true)

          def self.batch(client, items = [])
            Batch.new(self, client, items)
          end
        end
      end

      let(:batch) do
        klass.configure_client(client: stub_client)
        klass.batch(stub_client, valid_items)
      end

      let(:stub_client) { Aws::DynamoDB::Client.new(stub_responses: true) }

      let(:valid_items) do
        k1 = klass.new
        k1.id = 1
        k2 = klass.new
        k2.id = 2
        k3 = klass.new
        k3.id = 3
        [k1, k2, k3]
      end

      let(:invalid_items) { [klass.new, Array, klass.new] }

      describe "#initialize" do
        it 'returns a batch_writer object with items passed in' do
          expect(batch).to be_a(Batch)
        end

        it 'raises an error when items array contains non-parent object' do
          klass.configure_client(client: stub_client)
          expect do
            klass.batch(stub_client, invalid_items)
          end.to raise_error(ArgumentError)
        end
      end

      describe "#each" do
        it "correctly iterates through all items" do
          expect(batch.map(&:id)).to eq([1,2,3])
        end
      end

      describe "#add" do
        it "adds an item of the same class" do
          batch.add(klass.new)
          expect(batch.map(&:id).size).to eq valid_items.size + 1
        end

        it "raises ArgumentError on non-class item add" do
          expect { batch.add([]) }.to raise_error(ArgumentError)
        end

        it "does not increase in size when adding item already included" do
          batch.add(valid_items.first)
          expect(batch.map(&:id).size).to eq valid_items.size
        end
      end

      describe "#size" do
        it "returns the correct size" do
          expect(batch.size).to eq valid_items.size
        end
      end

    end
  end
end

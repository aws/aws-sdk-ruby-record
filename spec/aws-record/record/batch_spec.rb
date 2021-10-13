# Copyright 2015-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

Planet = Class.new do
  include(Aws::Record)
  include(Aws::Record::Batch)
  integer_attr(:id, hash_key: true)
  string_attr(:name, range_key: true)
end

describe Aws::Record::Batch do
  let(:client) { Aws::DynamoDB::Client.new(stub_responses: true) }

  before(:each) do
    Planet.configure_client(client: client)
  end

  describe '#batch_write' do
    let(:pluto) { Planet.find(id: 9, name: 'pluto') }
    let(:result) do
      Planet.batch_write do |db|
        db.put(Planet.new(id: 1, name: 'mercury'))
        db.put(Planet.new(id: 2, name: 'venus'))
        db.put(Planet.new(id: 3, name: 'earth'))
        db.put(Planet.new(id: 4, name: 'mars'))
        db.put(Planet.new(id: 5, name: 'jupiter'))
        db.put(Planet.new(id: 6, name: 'saturn'))
        db.put(Planet.new(id: 7, name: 'uranus'))
        db.put(Planet.new(id: 8, name: 'neptune'))
        db.delete(pluto) # sorry :(
      end
    end

    before(:each) do
      client.stub_responses(
        :get_item,
        item: {
          'id' => 9,
          'name' => 'pluto'
        }
      )
    end

    context 'when all operations succeed' do
      before(:each) do
        client.stub_responses(
          :batch_write_item,
          unprocessed_items: {}
        )
      end

      it 'writes a batch of operations' do
        expect(result).to be_an(Aws::Record::BatchWrite)
      end

      it 'is not retryable' do
        expect(result).not_to be_retryable
      end
    end

    context 'when some operations fail' do
      before(:each) do
        client.stub_responses(
          :batch_write_item,
          unprocessed_items: {
            'planet' => [
              { put_request: { item: { 'id' => 3, 'name' => 'earth' } } },
              { delete_request: { key: { 'id' => 9, 'name' => 'pluto' } } }
            ]
          }
        )
      end

      it 'sets the unprocessed_items attribute' do
        expect(result.unprocessed_items['planet'].size).to eq(2)
      end

      it 'is retryable' do
        expect(result).to be_retryable
      end
    end
  end
end

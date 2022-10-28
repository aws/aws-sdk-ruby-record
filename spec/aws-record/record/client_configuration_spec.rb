# Copyright 2015-2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
    describe 'ClientConfiguration' do

      describe 'inheritance support for dynamodb client' do
        let(:parent_class) do
          Class.new do
            include(Aws::Record)
            integer_attr(:id, hash_key: true)
          end
        end

        let(:child_class) do
          Class.new(parent_class) do
            include(Aws::Record)
            string_attr(:foo)
          end
        end

        let(:stub_client) { Aws::DynamoDB::Client.new(stub_responses: true) }

        # two things mock can do:
        # expect calls to test behavior
        # setting up tests effectively in mocking behavior

        it 'should have child class inherit dynamodb client from parent class' do
          parent_class.configure_client(client: stub_client)
          child_class.dynamodb_client
          expect(parent_class.dynamodb_client).to eq(child_class.dynamodb_client)
        end

        it 'should have child class maintain its own dynamodb client if defined in class' do
          child_class.configure_client(client: stub_client)
          expect(child_class.dynamodb_client).not_to eql(parent_class.dynamodb_client)
        end
      end

    end
  end
end
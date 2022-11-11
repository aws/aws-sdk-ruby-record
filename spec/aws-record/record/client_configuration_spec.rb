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

      context 'inheritance support for dynamodb client' do
        let(:parent_model) do
          Class.new do
            include(Aws::Record)
          end
        end

        let(:child_model) do
          Class.new(parent_model) do
            include(Aws::Record)
          end
        end

        let(:stub_client) { Aws::DynamoDB::Client.new(stub_responses: true) }

        it 'should have child model inherit dynamodb client from parent model' do
          parent_model.configure_client(client: stub_client)
          child_model.dynamodb_client
          expect(parent_model.dynamodb_client).to eq(child_model.dynamodb_client)
        end

        it 'should have child model maintain its own dynamodb client if defined in model' do
          parent_model.configure_client(client: stub_client)
          child_model.configure_client(client: stub_client.dup)
          expect(child_model.dynamodb_client).not_to eql(parent_model.dynamodb_client)
        end
      end

    end
  end
end
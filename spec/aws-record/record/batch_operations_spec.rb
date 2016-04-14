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
    describe "BatchOperations" do

      let(:klass) do
        Class.new do
          include(Aws::Record)
          set_table_name("TestTable")
          integer_attr(:id, hash_key: true)
        end
      end

      let(:stub_client) { Aws::DynamoDB::Client.new(stub_responses: true) }

      describe ".batch_writer" do
        it 'returns a batch_writer object with no items passed in' do
          klass.configure_client(client: stub_client)
          batch_writer = klass.batch_writer
          expect(batch_writer).to be_a(BatchWriter)
        end
      end

    end
  end
end

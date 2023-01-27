# frozen_string_literal: true

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
          expect(parent_model.dynamodb_client).to be(child_model.dynamodb_client)
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

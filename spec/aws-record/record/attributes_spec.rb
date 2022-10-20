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
    describe 'Attributes' do

      let(:klass) do
        Class.new do
          include(Aws::Record)
        end
      end

      describe '#initialize' do
        let(:model) do
          Class.new do
            include(Aws::Record)
            string_attr(:id, hash_key: true)
            string_attr(:body)
          end
        end

        it 'should allow attribute assignment at item creation time' do
          item = model.new(id: "MyId")
          expect(item.id).to eq("MyId")
          expect(item.body).to be_nil
        end

        it 'should allow assignment of multiple attributes at item creation' do
          item = model.new(id: "MyId", body: "Hello!")
          expect(item.id).to eq("MyId")
          expect(item.body).to eq("Hello!")
        end
      end

      describe 'Keys' do
        it 'should be able to assign a hash key' do
          klass.string_attr(:mykey, hash_key: true)
          klass.string_attr(:other)
          expect(klass.hash_key).to eq(:mykey)
        end

        it 'should be able to assign a hash and range key' do
          klass.string_attr(:mykey, hash_key: true)
          klass.string_attr(:ranged, range_key: true)
          klass.string_attr(:other)
          expect(klass.hash_key).to eq(:mykey)
          expect(klass.range_key).to eq(:ranged)
        end

        it 'should reject assigning the same attribute as hash and range key' do
          expect {
            klass.string_attr(:oops, hash_key: true, range_key: true)
          }.to raise_error(ArgumentError)
        end
      end

      describe 'Attributes' do
        it 'should create dynamic methods around attributes' do
          klass.string_attr(:text)
          x = klass.new
          x.text = "Hello world!"
          expect(x.text).to eq("Hello world!")
        end

        it 'should reject non-symbolized attribute names' do
          expect { klass.float_attr("floating") }.to raise_error(ArgumentError)
        end

        it 'rejects collisions of db storage names with existing attr names' do
          klass.string_attr(:dup_name, database_attribute_name: 'dup_storage')
          expect {
            klass.string_attr(:fail, database_attribute_name: 'dup_name')
          }.to raise_error(Aws::Record::Errors::NameCollision)
        end

        it 'rejects collisions of attr names with existing db storage names' do
          klass.string_attr(:dup_name, database_attribute_name: 'dup_storage')
          expect {
            klass.string_attr(:dup_storage, database_attribute_name: 'fail')
          }.to raise_error(Aws::Record::Errors::NameCollision)
        end

        it 'should not allow duplicate assignment of the same attr name' do
          klass.string_attr(:duplication)
          expect { klass.datetime_attr(:duplication) }.to raise_error(
            Aws::Record::Errors::NameCollision
          )
        end

        it 'should typecast an integer attribute' do
          klass.integer_attr(:num)
          x = klass.new
          x.num = "5"
          expect(x.num).to eq(5)
        end

        it 'should display a hash representation of attribute raw values' do
          klass.string_attr(:a)
          klass.string_attr(:b)
          x = klass.new
          x.a = "5"
          x.b = 5
          expect(x.to_h).to eq({a: "5", b: 5})
        end

        it 'should allow specification of a separate storage attribute name' do
          klass.string_attr(:a, database_attribute_name: 'column_a')
          klass.string_attr(:b)
          expect(klass.attributes.storage_name_for(:a)).to eq('column_a')
          expect(klass.attributes.storage_name_for(:b)).to eq('b')
        end

        it 'should reject storage name collisions' do
          klass.string_attr(:a, database_attribute_name: 'column_a')
          expect {
            klass.string_attr(:column_a)
          }.to raise_error(Errors::NameCollision)
          expect(klass.attributes.present?(:column_a)).to be_falsy
        end

        it 'should enforce uniqueness of storage names' do
          klass.string_attr(:a, database_attribute_name: 'unique')
          expect {
            klass.string_attr(:b, database_attribute_name: 'unique')
          }.to raise_error(Errors::NameCollision)
        end

        it 'should not allow collisions with reserved names' do
          expect {
            klass.string_attr(:to_h)
          }.to raise_error(Errors::ReservedName)
        end

        it 'should allow reserved names to be used as custom storage names' do
          klass.string_attr(:clever, database_attribute_name: 'to_h')
          item = klass.new
          item.clever = "No problem."
          expect(item.to_h).to eq({ clever: "No problem." })
        end
      end

      describe '#atomic_counter' do
        it 'should override the existing default value' do
          klass.string_attr(:id, hash_key: true)
          klass.atomic_counter(:counter, default_value: 5)
          item = klass.new(id: "MyId")
          expect(item.counter).to eq(5)
        end

        it 'should be the existing default value' do
          klass.string_attr(:id, hash_key: true)
          klass.atomic_counter(:counter)
          item = klass.new(id: "MyId")
          expect(item.counter).to eq(0)
        end

        it 'should be able to reassign default value after creation' do
          klass.string_attr(:id, hash_key: true)
          klass.atomic_counter(:counter, default_value: 5)
          item = klass.new(id: "MyId")
          item.counter = 10
          expect(item.counter).to eq(10)
        end

        describe '#incrementing_<attr>!' do

          before(:each) do
            klass.configure_client(client: stub_client)
          end

          let(:klass) do
            Class.new do
              include(Aws::Record)
              set_table_name("TestTable")
              integer_attr(:id, hash_key: true)
              atomic_counter(:counter)
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

          it 'should increment atomic counter by default value' do
            stub_client.stub_responses(:update_item,
               {
                 attributes:
                   {
                     'counter' => 1
                   }
               })

            item = klass.new(id: 1)
            item.save!
            item.increment_counter!

            expect(item.counter).to eq(1)
            expect(api_requests[1]). to eq({
              expression_attribute_names: {"#n"=>"counter"},
              expression_attribute_values: {":i"=>{:n=>"1"}},
              key: {"id"=>{:n=>"1"}},
              return_values: "UPDATED_NEW",
              table_name: "TestTable",
              update_expression:"SET #n = #n + :i"
            })
          end

          it 'should increment the atomic counter by a custom value' do
            stub_client.stub_responses(:update_item,
               {
                 attributes:
                   {
                     'counter' => 2
                   }
               })

            item = klass.new(id: 1)
            item.save!
            item.increment_counter!(2)

            expect(item.counter).to eq(2)
            expect(api_requests[1]). to eq({
             expression_attribute_names: {"#n"=>"counter"},
             expression_attribute_values: {":i"=>{:n=>"2"}},
             key: {"id"=>{:n=>"1"}},
             return_values: "UPDATED_NEW",
             table_name: "TestTable",
             update_expression:"SET #n = #n + :i"
           })
          end

          it 'will raise when incrementing on a dirty item' do
            item = klass.new(id: 1)
            expect { item.increment_counter! }.to raise_error(Errors::RecordError)
          end

          it 'will raise when arg is not an integer' do
            item = klass.new(id: 1)
            item.save!
            expect {item.increment_counter!("foo")}.to raise_error(ArgumentError)
          end
        end
      end

      # Did not want to interfere with other existing blocks above
      # so created a separate block to test inheritance between classes
      describe 'inheritance support' do
        let(:parent_class) do
          Class.new do
            include(Aws::Record)
            integer_attr(:id, hash_key: true)
            date_attr(:date, range_key: true)
            list_attr(:list)
          end
        end

        let(:child_class) do
          Class.new(parent_class) do
            include(Aws::Record)
            string_attr(:body)
          end
        end

        let(:child_class2) do
          Class.new(parent_class) do
            include(Aws::Record)
            string_attr(:body2)
          end
        end

        it 'should have instances of child classes with parent attributes' do
        end

        it 'should have instances of parent class with its own attributes' do
        end

        it 'should let child class override attribute keys' do
        end

        it 'correctly passes default values to child class' do
        end

        it 'lets parent class maintain its own attributes after changes' do
        end


      end
    end
  end
end

require 'spec_helper'

module Aws
  module Record
    describe 'Attributes' do

      let(:klass) do
        Class.new do
          include(Aws::Record)
        end
      end

      describe 'Keys' do
        it 'should be able to assign a hash key' do
          klass.string_attr(:mykey, hash_key: true)
          klass.string_attr(:other)
          expect(klass.hash_key.name).to eq(:mykey)
        end

        it 'should be able to assign a hash and range key' do
          klass.string_attr(:mykey, hash_key: true)
          klass.string_attr(:ranged, range_key: true)
          klass.string_attr(:other)
          expect(klass.hash_key.name).to eq(:mykey)
          expect(klass.range_key.name).to eq(:ranged)
        end
      end

      describe 'Attributes' do
        it 'should create dynamic methods around attributes' do
          klass.string_attr(:text)
          x = klass.new
          x.text = "Hello world!"
          expect(x.text).to eq("Hello world!")
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
          expect(klass.attributes[:a].database_name).to eq('column_a')
          expect(klass.attributes[:b].database_name).to eq('b')
        end

        it 'should be able to look up an attribute by its storage name' do
          klass.string_attr(:a, database_attribute_name: 'column_a')
          expect(klass.attribute_name('column_a')).to eq(:a)
        end

        it 'should reject storage name collisions' do
          klass.string_attr(:a, database_attribute_name: 'column_a')
          expect {
            klass.string_attr(:column_a)
          }.to raise_error(Errors::NameCollision)
          expect(klass.attributes[:column_a]).to be_nil
        end

        it 'should enforce uniqueness of storage names' do
          klass.string_attr(:a, database_attribute_name: 'unique')
          expect {
            klass.string_attr(:b, database_attribute_name: 'unique')
          }.to raise_error(Errors::NameCollision)
        end
      end

    end
  end
end

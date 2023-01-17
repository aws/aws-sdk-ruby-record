# frozen_string_literal: true

require 'spec_helper'

module Aws
  module Record
    describe Attribute do

      context 'database_attribute_name' do
        it 'can have a custom DB name' do
          a = Attribute.new(:foo, database_attribute_name: "bar")
          expect(a.name).to eq(:foo)
          expect(a.database_name).to eq("bar")
        end

        it 'can accept a symbol as a custom DB name' do
          a = Attribute.new(:foo, database_attribute_name: :bar)
          expect(a.name).to eq(:foo)
          expect(a.database_name).to eq("bar")
        end

        it 'uses the attribute name by default for the DB name' do
          a = Attribute.new(:foo)
          expect(a.name).to eq(:foo)
          expect(a.database_name).to eq("foo")
        end
      end

      context 'default_value' do
        it 'supports lambdas' do
          a = Attribute.new(:foo, default_value: -> { 2 + 3 })
          expect(a.default_value).to eq(5)
        end

        it 'does not type_cast lambdas' do
          m = Marshalers::DateTimeMarshaler.new
          a = Attribute.new(:foo, marshaler: m, default_value: -> { Time.now })
          dv = a.instance_variable_get("@default_value_or_lambda")
          expect(dv.respond_to?(:call)).to eq(true)
        end

        it 'type casts result of calling a default_value lambda' do
          m = Marshalers::StringMarshaler.new
          a = Attribute.new(:foo, marshaler: m, default_value: -> { :huzzah })
          expect(a.default_value).to be_a(String)
        end

        it 'uses a deep copy' do
          a = Attribute.new(:foo, default_value: {})
          a.default_value['greeting'] = 'hi'

          expect(a.default_value).to eq({})
        end
      end

    end
  end
end

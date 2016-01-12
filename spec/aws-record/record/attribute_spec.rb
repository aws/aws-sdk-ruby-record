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
    describe Attribute do

      it 'can have a custom DB name' do
        a = Attribute.new(:foo, database_attribute_name: "bar")
        expect(a.name).to eq(:foo)
        expect(a.database_name).to eq("bar")
      end

      describe 'validation' do

        let(:noop_validator) do
          Class.new do
            def self.validate(value)
              true
            end
          end
        end

        let(:failure_validator) do
          Class.new do
            def self.validate(value)
              false
            end
          end
        end

        it 'passes validation on to a validator chain' do
          a = Attribute.new(:test, validators: [noop_validator])
          expect(a.valid?("Hello")).to eq(true)
        end

        it 'fails validation if any validator in the chain fails' do
          a = Attribute.new(
            :test, validators: [failure_validator, noop_validator]
          )
          expect(a.valid?("Hello")).to eq(false)
        end

      end

    end
  end
end

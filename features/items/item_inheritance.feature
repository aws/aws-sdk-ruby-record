# Copyright 2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

# language: en

@dynamodb @item
Feature: Amazon DynamoDB Item Inheritance
  This feature tests inheritance between parent class and child classes. To run
  these tests, you will need to have valid AWS credentials that are accessible
  with the AWS SDK for Ruby's standard credential provider chain. In practice,
  this means a shared credential file or environment variables with your credentials.
  These tests may have some AWS costs associated with running them since AWS resources
  are created and destroyed within these tests.

  Background:
    Given a DynamoDB table named 'Animal' with data:
    """
    [
      { "attribute_name": "name", "attribute_type": "S", "key_type": "HASH" },
      { "attribute_name": "age", "attribute_type": "N", "key_type": "RANGE" },
    ]
    """
    And an aws-record model with data:
    """
    [
      { "method": "string_attr", "name": "name", "hash_key": true },
      { "method": "integer_attr", "name": "age", "range_key": true },
      { "method": "string_attr", "name": "size", "default_value": "None" }
    ]
    """


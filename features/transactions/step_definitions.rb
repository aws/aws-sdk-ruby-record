When("we make a transact_find call with parameters:") do |param_block|
  params = eval(param_block)
  @transact_get_result = TableConfigTestModel.transact_find(params)
end

Then("we expect a transact_find result that includes the following items:") do |result_block|
  item_params = eval(result_block)
  expected = item_params.map do |params|
    if nil
      nil
    else
      TableConfigTestModel.new(params)
    end
  end
  expect(@transact_get_result.items).to eq(expected)
end

When("we make a global transact_find call with parameters:") do |param_block|
  params = eval(param_block)
  @transact_get_result = Aws::Record::Transactions.transact_find(params)
end

Then("we expect a transact_find result that includes the following items:") do |result_block|
  tfind_result = eval(result_block)
  expected = tfind_result.map do |item|
    if item.nil?
      nil
    else
      item.to_h
    end
  end
  expect(@transact_get_result.items).to eq(expected)
end

When("we run the following code:") do |code|
  @arbitrary_code_ret = eval(code)
end

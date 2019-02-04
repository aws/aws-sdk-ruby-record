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
  begin
    @arbitrary_code_ret = eval(code)
  rescue StandardError => e
    @arbitrary_code_exception = e
  end
end

Then("we expect the code to raise an {string} exception") do |exception_class|
  expect(@arbitrary_code_exception.class).to eq(Kernel.const_get(exception_class))
end

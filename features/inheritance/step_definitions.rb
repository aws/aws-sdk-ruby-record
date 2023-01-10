Given(/^a (Parent|Child) model with definition:$/) do |model, string|
  case model
    when 'Parent'
      @parent = Class.new do
        include(Aws::Record)
      end
      @parent.class_eval(string)
      @table_name = @parent.table_name
    when 'Child'
      @model = Class.new(@parent) do
        include(Aws::Record)
      end
      @model.class_eval(string)
      @table_name = @model.table_name
  else
      raise 'Model must be either a Parent or Child'
  end
end

And(/^we create a new instance of the (Parent|Child) model with attribute value pairs:$/) do |model, string|
  data = JSON.parse(string)
  case model
    when 'Parent'
      @instance = @parent.new
    when 'Child'
      @instance = @model.new
    else
      raise 'Model must be either a Parent or Child'
  end
  data.each do |row|
    attribute, value = row
    @instance.send(:"#{attribute}=", value)
  end
end
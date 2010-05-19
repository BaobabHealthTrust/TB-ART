# We should improve this matcher okay? 
Then /^(?:|I )should see the question "([^\"]*)"(?: within "([^\"]*)")?$/ do |text, selector|
  with_scope(selector) do  
    if defined?(Spec::Rails::Matchers)
      page.body.should =~ /#{text}/ #
    end
  end
end

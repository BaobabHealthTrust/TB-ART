
Given /^(?:|I )wait (\d+) seconds*$/ do |seconds|
  sleep(seconds.to_i)
end

Then /^dump the page$/ do
  puts body
end

# Doesn't work
Then /^lynxdump the page$/ do
  puts `echo #{body} | lynx -stdin -dump`
end

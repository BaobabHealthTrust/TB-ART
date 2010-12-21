Factory.define :program, :class => :program do |program|
  program.name { |n| "foo#{n}" }
  program.concept Factory(:concept)
  program.creator { Factory.creator }
end

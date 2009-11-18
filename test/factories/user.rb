
class Factory
  # You need a single user to start the system
  User.destroy_all

  @@creator = User.create(
    :user_id => 1, 
    :username => 'default', 
    :plain_password => 'password')
  
  def self.creator
    @@creator.user_id
  end
end  

Factory.sequence :username do |n|
  "USER#{n}"
end

Factory.define :user, :class => :user do |user|
  user.creator         { Factory.creator } 
  user.username        { Factory.next :username }
  user.plain_password  { "password" }
  user.system_id       { "Parters in Health Admin" }
end
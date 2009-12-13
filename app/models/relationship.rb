class Relationship < ActiveRecord::Base
  set_table_name :relationship
  set_primary_key :relationship_id
  include Openmrs
  named_scope :active, :conditions => ['relationship.voided = 0']
  belongs_to :person, :class_name => 'Person', :foreign_key => :person_a, :conditions => 'person.voided = 0'
  belongs_to :relation, :class_name => 'Person', :foreign_key => :person_b, :conditions => 'person.voided = 0'
  belongs_to :type, :class_name => "RelationshipType", :foreign_key => :relationship
  
  def to_s
    self.type.b_is_to_a + ": " + relation.name
  end
end
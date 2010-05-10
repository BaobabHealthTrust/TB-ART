class Concept < ActiveRecord::Base
  set_table_name :concept
  set_primary_key :concept_id
  include Openmrs

  belongs_to :concept_class, :conditions => {:retired => 0}
  belongs_to :concept_datatype, :conditions => {:retired => 0}
  has_one :concept_numeric, :foreign_key => :concept_id, :dependent => :destroy
  has_one :name, :class_name => 'ConceptName'
  has_many :answer_concept_names, :class_name => 'ConceptName', :conditions => {:voided => 0}
  has_many :concept_names, :conditions => {:voided => 0}
  has_many :concept_maps # no default scope
  has_many :concept_sets  # no default scope
  has_many :concept_answers do # no default scope
    def limit(search_string)
      return self if search_string.blank?
      map{|concept_answer|
        concept_answer if concept_answer.name.match(search_string)
      }.compact
    end
  end
  has_many :drugs, :conditions => {:retired => 0}
end

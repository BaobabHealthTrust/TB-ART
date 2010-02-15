class Order < ActiveRecord::Base
  include Openmrs
  set_table_name :orders
  set_primary_key :order_id
  belongs_to :order_type
  belongs_to :concept
  belongs_to :encounter
  belongs_to :patient
  belongs_to :provider, :foreign_key => 'orderer', :class_name => 'User'
  belongs_to :observation, :foreign_key => 'obs_id', :class_name => 'Observation'
  has_one :drug_order
  named_scope :active, :conditions => ['voided = 0']
  named_scope :unfinished, :conditions => ['discontinued = 0 AND auto_expire_date > NOW()']
  named_scope :finished, :conditions => ['discontinued = 1 OR auto_expire_date < NOW()']
  named_scope :arv, :lambda {|order|
    arv_concept = ConceptName.find_by_name("ANTIRETROVIRAL DRUGS").concept_id
    arv_drug_concepts = ConceptSet.all(:conditions => ['concept_set = ?', arv_concept])
    {:conditions => ['concept_id IN (?)', arv_drug_concepts.map(&:concept_id)]}
  }
  named_scope :labs, :conditions => ['drug_order.drug_inventory_id is NULL'], :include => :drug_order
  named_scope :prescriptions, :conditions => ['drug_order.drug_inventory_id is NOT NULL'], :include => :drug_order
  
  def to_s
    "#{drug_order}"
  end
end


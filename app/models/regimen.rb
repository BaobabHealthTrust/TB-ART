class Regimen < ActiveRecord::Base
  set_table_name "regimen"
  set_primary_key "regimen_id"
  include Openmrs
  belongs_to :regimen_criteria  
  belongs_to :drug, :foreign_key => :drug_inventory_id
  named_scope :active, {} # :conditions => ['regimen.voided = 0']
    
  def to_s 
    s = "#{drug.name}: #{self.dose} #{self.units} #{frequency}"
    s << " (prn)" if prn == 1
    s
  end
  
end
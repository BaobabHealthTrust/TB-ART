class Patient < ActiveRecord::Base
  set_table_name "patient"
  set_primary_key "patient_id"
  include Openmrs

  has_one :person, :foreign_key => :person_id, :conditions => {:voided => 0}
  has_many :patient_identifiers, :foreign_key => :patient_id, :dependent => :destroy, :conditions => {:voided => 0}
  has_many :patient_programs, :conditions => {:voided => 0}
  has_many :programs, :through => :patient_programs
  has_many :relationships, :foreign_key => :person_a, :dependent => :destroy, :conditions => {:voided => 0}
  has_many :orders, :conditions => {:voided => 0}
  has_many :encounters, :conditions => {:voided => 0} do 
    def find_by_date(encounter_date)
      encounter_date = Date.today unless encounter_date
      find(:all, :conditions => ["DATE(encounter_datetime) = DATE(?)", encounter_date]) # Use the SQL DATE function to compare just the date part
    end
  end

  def after_void(reason = nil)
    self.person.void(reason) rescue nil
    self.patient_identifiers.each {|row| row.void(reason) }
    self.patient_programs.each {|row| row.void(reason) }
    self.orders.each {|row| row.void(reason) }
    self.encounters.each {|row| row.void(reason) }
  end

  def current_diagnoses
    self.encounters.current.all(:include => [:observations]).map{|encounter| 
      encounter.observations.all(
        :conditions => ["obs.concept_id = ? OR obs.concept_id = ?", 
        ConceptName.find_by_name("DIAGNOSIS").concept_id,
        ConceptName.find_by_name("DIAGNOSIS, NON-CODED").concept_id])
    }.flatten.compact
  end

  def current_treatment_encounter
    type = EncounterType.find_by_name("TREATMENT")
    encounter = encounters.current.find_by_encounter_type(type.id)
    encounter ||= encounters.create(:encounter_type => type.id)
  end

  def current_dispensation_encounter
    type = EncounterType.find_by_name("DISPENSING")
    encounter = encounters.current.find_by_encounter_type(type.id)
    encounter ||= encounters.create(:encounter_type => type.id)
  end
    
  def alerts
    # next appt
    # adherence
    # drug auto-expiry
    # cd4 due    
  end
  
  def summary
#    verbiage << "Last seen #{visits.recent(1)}"
    verbiage = []
    verbiage << patient_programs.map{|prog| "Started #{prog.program.name.humanize} #{prog.date_enrolled.strftime('%b-%Y')}" rescue nil }
    verbiage << orders.unfinished.prescriptions.map{|presc| presc.to_s}
    verbiage.flatten.compact.join(', ') 
  end

  def national_id(force = true)
    id = self.patient_identifiers.find_by_identifier_type(PatientIdentifierType.find_by_name("National id").id).identifier rescue nil
    return id unless force
    id ||= PatientIdentifierType.find_by_name("National id").next_identifier(:patient => self).identifier
    id
  end

  def national_id_with_dashes(force = true)
    id = self.national_id(force)
    id[0..4] + "-" + id[5..8] + "-" + id[9..-1] rescue id
  end

  def national_id_label
    return unless self.national_id
    sex =  self.person.gender.match(/F/i) ? "(F)" : "(M)"
    address = self.person.address.strip[0..24].humanize.delete("'") rescue ""
    label = ZebraPrinter::StandardLabel.new
    label.font_size = 2
    label.font_horizontal_multiplier = 2
    label.font_vertical_multiplier = 2
    label.left_margin = 50
    label.draw_barcode(50,180,0,1,5,15,120,false,"#{self.national_id}")
    label.draw_multi_text("#{self.person.name.titleize.delete("'")}") #'
    label.draw_multi_text("#{self.national_id_with_dashes} #{self.person.birthdate_formatted}#{sex}")
    label.draw_multi_text("#{address}")
    label.print(1)
  end
  
  def visit_label(date = Date.today)
    label = ZebraPrinter::StandardLabel.new
    label.font_size = 3
    label.font_horizontal_multiplier = 1
    label.font_vertical_multiplier = 1
    label.left_margin = 50
    encs = encounters.find(:all,:conditions =>["DATE(encounter_datetime) = ?",date])
    return nil if encs.blank?
    
    label.draw_multi_text("Visit: #{encs.first.encounter_datetime.strftime("%d/%b/%Y %H:%M")}", :font_reverse => true)    
    encs.each {|encounter|
      next if encounter.name.humanize == "Registration"
      label.draw_multi_text("#{encounter.name.humanize}: #{encounter.to_s}", :font_reverse => false)
    }
    label.print(1)
  end
  
  def get_identifier(type = 'National id')
    identifier_type = PatientIdentifierType.find_by_name(type)
    return if identifier_type.blank?
    identifiers = self.patient_identifiers.find_all_by_identifier_type(identifier_type.id)
    return if identifiers.blank?
    identifiers.map{|i|i.identifier}.join(' , ') rescue nil
  end
  
  def current_weight
    obs = person.observations.recent(1).question("WEIGHT (KG)").all
    obs.first.value_numeric rescue 0
  end
  
  def current_height
    obs = person.observations.recent(1).question("HEIGHT (CM)").all
    obs.first.value_numeric rescue 0
  end
  
  def initial_weight
    obs = person.observations.recent(1).question("WEIGHT (KG)").all
    obs.last.value_numeric rescue 0
  end
  
  def initial_height
    obs = person.observations.recent(1).question("HEIGHT (CM)").all
    obs.last.value_numeric rescue 0
  end

  def initial_bmi
    obs = person.observations.recent(1).question("BMI").all
    obs.last.value_numeric rescue nil
  end

  def min_weight
    WeightHeight.min_weight(person.gender, person.age_in_months).to_f
  end
  
  def max_weight
    WeightHeight.max_weight(person.gender, person.age_in_months).to_f
  end
  
  def min_height
    WeightHeight.min_height(person.gender, person.age_in_months).to_f
  end
  
  def max_height
    WeightHeight.max_height(person.gender, person.age_in_months).to_f
  end
  
  def given_arvs_before?
    self.orders.each{|order|
      drug_order = order.drug_order
      next unless drug_order.quantity > 0
      return true if drug_order.drug.arv?
    }
    false
  end

  def name
    "#{self.person.name}"
  end

 def self.dead_with_visits(start_date, end_date)

  patient_died_concept = ConceptName.find_by_name('PATIENT DIED').concept_id

  dead_patients = "SELECT dead_patient_program.patient_program_id,
    dead_state.state, dead_patient_program.patient_id, dead_state.date_changed
    FROM patient_state dead_state INNER JOIN patient_program dead_patient_program
    ON   dead_state.patient_program_id = dead_patient_program.patient_program_id
    WHERE  EXISTS
      (SELECT * FROM program_workflow_state p
        WHERE dead_state.state = program_workflow_state_id AND concept_id = #{patient_died_concept})
          AND dead_state.date_changed >='#{start_date}' AND dead_state.date_changed <= '#{end_date}'"

  living_patients = "SELECT living_patient_program.patient_program_id,
    living_state.state, living_patient_program.patient_id, living_state.date_changed
    FROM patient_state living_state
    INNER JOIN patient_program living_patient_program
    ON living_state.patient_program_id = living_patient_program.patient_program_id
    WHERE  NOT EXISTS
      (SELECT * FROM program_workflow_state p
        WHERE living_state.state = program_workflow_state_id AND concept_id =  #{patient_died_concept})"

  dead_patients_with_observations_visits = "SELECT death_observations.person_id,death_observations.obs_datetime AS date_of_death, active_visits.obs_datetime AS date_living
    FROM obs active_visits INNER JOIN obs death_observations
    ON death_observations.person_id = active_visits.person_id
    WHERE death_observations.concept_id != active_visits.concept_id AND death_observations.concept_id =  #{patient_died_concept} AND death_observations.obs_datetime < active_visits.obs_datetime
      AND active_visits.obs_datetime >='#{start_date}' AND death_observations.obs_datetime <= '#{end_date}'"

  all_dead_patients_with_visits = " SELECT dead.patient_id, dead.date_changed AS dealth_date, living.date_changed
    FROM (#{dead_patients}) dead,  (#{living_patients}) living
    WHERE living.patient_id = dead.patient_id AND dead.date_changed < living.date_changed
    UNION ALL #{dead_patients_with_observations_visits}"

    self.find_by_sql([all_dead_patients_with_visits])
  end

  def self.males_allegedly_pregnant(start_date, end_date)
    pregnant_patient_concept_id = ConceptName.find_by_name('PATIENT PREGNANT').concept_id

    PatientIdentifier.find_by_sql(["SELECT person.person_id,obs.obs_datetime
                                   FROM obs INNER JOIN person
                                   ON obs.person_id = person.person_id
                                   WHERE person.gender = 'M' AND
                                   obs.concept_id = ? AND obs.obs_datetime >= ? AND obs.obs_datetime <= ?",
                                    pregnant_patient_concept_id, start_date, end_date])
  end

  def self.with_drug_start_dates_less_than_program_enrollment_dates(start_date, end_date)

    PatientIdentifier.find_by_sql("SELECT person.person_id,obs.obs_datetime
                                   FROM obs INNER JOIN person
                                   ON obs.person_id = person.person_id
                                   WHERE person.gender = 'M' AND obs.concept_id = 1742")
  end
end

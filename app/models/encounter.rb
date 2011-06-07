class Encounter < ActiveRecord::Base
  set_table_name :encounter
  set_primary_key :encounter_id
  include Openmrs
  has_many :observations, :dependent => :destroy, :conditions => {:voided => 0}
  has_many :drug_orders,  :through   => :orders,  :foreign_key => 'order_id'
  has_many :orders, :dependent => :destroy, :conditions => {:voided => 0}
  belongs_to :type, :class_name => "EncounterType", :foreign_key => :encounter_type, :conditions => {:retired => 0}
  belongs_to :provider, :class_name => "User", :foreign_key => :provider_id, :conditions => {:voided => 0}
  belongs_to :patient, :conditions => {:voided => 0}

  # TODO, this needs to account for current visit, which needs to account for possible retrospective entry
  named_scope :current, :conditions => 'DATE(encounter.encounter_datetime) = CURRENT_DATE()'

  def before_save    
    self.provider = User.current_user if self.provider.blank?
    # TODO, this needs to account for current visit, which needs to account for possible retrospective entry
    self.encounter_datetime = Time.now if self.encounter_datetime.blank?
  end

  def after_void(reason = nil)
    self.orders.each{|row| Pharmacy.voided_stock_adjustment(order) if row.order_type_id == 1 }
    self.observations.each{|row| row.void(reason) }
    selfnd_by_sql("SELECT * FROM encounter ORDER BY encounter_datetime DESC LIMIT 1").orders.each{|row| row.void(reason) }
  end

  def encounter_type_name=(encounter_type_name)
    self.type = EncounterType.find_by_name(encounter_type_name)
    raise "#{encounter_type_name} not a valid encounter_type" if self.type.nil?
  end

  def self.initial_encounter
    self.find_by_sql("SELECT * FROM encounter ORDER BY encounter_datetime LIMIT 1").first
  end

  def voided_observations
    voided_obs = Observation.find_by_sql("SELECT * FROM obs WHERE obs.encounter_id = #{self.encounter_id} AND obs.voided = 1")
    (!voided_obs.empty?) ? voided_obs : nil
  end

  def voided_orders
    voided_orders = Order.find_by_sql("SELECT * FROM orders WHERE orders.encounter_id = #{self.encounter_id} AND orders.voided = 1")
    (!voided_orders.empty?) ? voided_orders : nil
  end

  def name
    self.type.name rescue "N/A"
  end

  def to_s
    if name == 'REGISTRATION'
      "Patient was seen at the registration desk at #{encounter_datetime.strftime('%I:%M')}" 
    elsif name == 'TREATMENT'
      o = orders.collect{|order| order.to_s}.join("\n")
      o = "No prescriptions have been made" if o.blank?
      o
    elsif name == 'VITALS'
      temp = observations.select {|obs| obs.concept.concept_names.map(&:name).include?("TEMPERATURE (C)") && "#{obs.answer_string}".upcase != 'UNKNOWN' }
      weight = observations.select {|obs| obs.concept.concept_names.map(&:name).include?("WEIGHT (KG)") && "#{obs.answer_string}".upcase != '0.0' }
      height = observations.select {|obs| obs.concept.concept_names.map(&:name).include?("HEIGHT (CM)") && "#{obs.answer_string}".upcase != '0.0' }
      vitals = [weight_str = weight.first.answer_string + 'KG' rescue 'UNKNOWN WEIGHT',
                height_str = height.first.answer_string + 'CM' rescue 'UNKNOWN HEIGHT']
      temp_str = temp.first.answer_string + '°C' rescue nil
      vitals << temp_str if temp_str                          
      vitals.join(', ')
    else  
      observations.collect{|observation| observation.answer_string}.join(", ")
    end  
  end

  def self.count_by_type_for_date(date)  
    # This query can be very time consuming, because of this we will not consider
    # that some of the encounters on the specific date may have been voided
    ActiveRecord::Base.connection.select_all("SELECT count(*) as number, encounter_type FROM encounter GROUP BY encounter_type")
    todays_encounters = Encounter.find(:all, :include => "type", :conditions => ["DATE(encounter_datetime) = ?",date])
    encounters_by_type = Hash.new(0)
    todays_encounters.each{|encounter|
      next if encounter.type.nil?
      encounters_by_type[encounter.type.name] += 1
    }
    encounters_by_type
  end

  def self.statistics(encounter_types, opts={})
    encounter_types = EncounterType.all(:conditions => ['name IN (?)', encounter_types])
    encounter_types_hash = encounter_types.inject({}) {|result, row| result[row.encounter_type_id] = row.name; result }
    with_scope(:find => opts) do
      rows = self.all(
         :select => 'count(*) as number, encounter_type', 
         :group => 'encounter.encounter_type',
         :conditions => ['encounter_type IN (?)', encounter_types.map(&:encounter_type_id)]) 
      return rows.inject({}) {|result, row| result[encounter_types_hash[row['encounter_type']]] = row['number']; result }
    end     
  end

  def self.visits_by_day(start_date,end_date)
    required_encounters = ["ART ADHERENCE", "ART_FOLLOWUP",   "ART_INITIAL",
                           "ART VISIT",     "HIV RECEPTION",  "HIV STAGING",
                           "PART_FOLLOWUP", "PART_INITIAL",   "VITALS"]

    required_encounters_ids = required_encounters.inject([]) do |encounters_ids, encounter_type|
      encounters_ids << EncounterType.find_by_name(encounter_type).id rescue nil
      encounters_ids
    end

    required_encounters_ids.sort!

    Encounter.find(:all,
      :joins      => ["INNER JOIN obs     ON obs.encounter_id    = encounter.encounter_id",
                      "INNER JOIN patient ON patient.patient_id  = encounter.patient_id"],
      :conditions => ["obs.voided = 0 AND encounter_type IN (?) AND encounter_datetime >=? AND encounter_datetime <=?",required_encounters_ids,start_date,end_date],
      :group      => "encounter.patient_id,DATE(encounter_datetime)",
      :order      => "encounter.encounter_datetime ASC")
  end

  def self.lab_activities
    lab_activities = [
      ['Lab Order', 'lab_order'],
      ['Sputum Submission', 'sputum_submission'],
      ['Lab Results', 'lab_results'],
    ]
  end

  def self.select_options
    select_options = {
     'reason_for_tb_clinic_visit' => [
        ['',''],
        ['Clinical examination','CLINICAL EXAMINATION'],
        ['Smear Negative','SMEAR NEGATIVE'],
        ['Smear Positive','SMEAR POSITIVE'],
        ['X-ray results','X-RAY RESULTS']
      ],
     'family_planning_methods' => [
       ['',''],
       ['Oral contraceptive pills', 'ORAL CONTRACEPTIVE PILLS'],
		   ['Depo-Provera', 'DEPO-PROVERA'],
		   ['Intrauterine contraception', 'INTRAUTERINE CONTRACEPTION'],
       ['Contraceptive implant', 'CONTRACEPTIVE IMPLANT'],
       ['Male condoms', 'MALE CONDOMS'],
       ['Female condoms', 'FEMALE CONDOMS'],
       ['Rhythm method', 'RYTHM METHOD'],
       ['Withdrawal', 'WITHDRAWAL'],
       ['Abstinence', 'ABSTINENCE'],
       ['Tubal ligation', 'TUBAL LIGATION'],
       ['Vasectomy', 'VASECTOMY'],
		   ['Emergency contraception', 'EMERGENCY CONTRACEPTION']
      ],
        'tb_symptoms' => [
          ['',''],
          ['Persistent cough', 'PERSISTENT COUGH'],
          ['Bronchial breathing', 'BRONCHIAL BREATHING'],
          ['Shortness of breath', 'SHORTNESS OF BREATH'],
          ['Crepitations', 'CREPITATIONS'],
          ['Failure to thrive', 'FAILURE TO THRIVE'],
          ['Chest pains', 'CHEST PAINS'],
          ['Loss of weight', 'LOST OF WEIGHT'],
          ['Recurrent fever', 'RECURRENT FEVER'],
          ['Lethargy', 'LETHARGY'],
          ['Haemoptysis', 'HAEMOPTYSIS'],
          ['Other','OTHER']
      ],
        'drug_related_side_effects' => [
          ['',''],
          ['Deafness', 'DEAFNESS'],
          ['Dizziness','DIZZINESS'],
          ['General reaction including shock', 'GENERAL REACTION'],
          ['Purpura', 'PURPURA'],
          ['Jaundice', 'JAUNDICE'],
          ['Skin itching', 'SKIN ITCHING'],
          ['Visual impairment', 'VISUAL IMPAIRMENT'],
          ['Vomiting ++/confusion', 'VOMITING']
      ],
        'drug_list' => [
          ['',''],
          ["Refampcin Isoniazid Pyrazinamide Ethambutol", "REFAMPCIN ISONIAZID PYRAZINAMIDE ETHAMBUTOL"],
          ["Refampcin Isoniazid Ethambutol", "REFAMPCIN ISONIAZID ETHAMBUTOL"],
          ["Refampcin Isoniazid", "REFAMPCIN ISONIAZID"],
          ["Stavudine Lamivudine Nevirapine", "STAVUDINE LAMIVUDINE NEVIRAPINE"],
          ["Stavudine Lamivudine + Stavudine Lamivudine Nevirapine", "STAVUDINE LAMIVUDINE + STAVUDINE LAMIVUDINE NEVIRAPINE"],
          ["Zidovudine Lamivudine + Nevirapine", "ZIDOVUDINE LAMIVUDINE + NEVIRAPINE"]
      ],
        'presc_time_period' => [
          ["",""],
          ["2 weeks", "2 WEEKS"],
          ["1 month", "1 MONTH"],
          ["2 months", "2 MONTHS"],
          ["3 months", "3 MONTHS"],
          ["4 months", "4 MONTHS"],
          ["5 months", "5 MONTHS"],
          ["6 months", "6 MONTHS"],
          ["7 months", "7 MONTHS"],
          ["8 months", "8 MONTHS"]
      ],
        'continue_treatment' => [
          ["",""],
          ["Yes", "YES"],
          ["Transfer Out", "TRANSFER OUT"]
      ]
    }
  end

end

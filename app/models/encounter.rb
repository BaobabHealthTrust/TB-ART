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
    self.find_by_sql("SELECT * FROM encounter ORDER BY encounter_datetime DESC LIMIT 1").orders.each{|row| row.void(reason) } rescue []
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
          ['Loss of weight', 'LOSS OF WEIGHT'],
          ['Recurrent fever', 'RECURRENT FEVER'],
          ['Lethargy', 'LETHARGY'],
          ['Haemoptysis', 'HAEMOPTYSIS'],
          ['Other','OTHER']
      ],
        'drug_related_side_effects' => [
          ['',''],
          ['Deafness', 'DEAFNESS'],
          ['Dizziness','DIZZINESS'],
          ['General reaction including shock', 'GENERAL REACTION INCLUDING SHOCK'],
          ['Purpura', 'PURPURA'],
          ['Jaundice', 'JAUNDICE'],
          ['Skin itching', 'SKIN ITCHING'],
          ['Visual impairment', 'VISUAL IMPAIRMENT'],
          ['Vomiting ++/confusion', 'VOMITING']
      ],
        'drug_list' => [
          ['',''],
          ["Rifampicin Isoniazid Pyrazinamide and Ethambutol", "RHEZ (RIF, INH, Ethambutol and Pyrazinamide tab)"],
          ["Rifampicin Isoniazid and Ethambutol", "RHE (Rifampicin Isoniazid and Ethambutol -1-1-mg t"],
          ["Rifampicin and Isoniazid", "RH (Rifampin and Isoniazid tablet)"],
          ["Stavudine Lamivudine and Nevirapine", "D4T+3TC+NVP"],
          ["Stavudine Lamivudine + Stavudine Lamivudine and Nevirapine", "D4T+3TC/D4T+3TC+NVP"],
          ["Zidovudine Lamivudine and Nevirapine", "AZT+3TC+NVP"]
      ],
        'presc_time_period' => [
          ["",""],
          ["1 month", "30"],
          ["2 months", "60"],
          ["3 months", "90"],
          ["4 months", "120"],
          ["5 months", "150"],
          ["6 months", "180"],
          ["7 months", "210"],
          ["8 months", "240"]
      ],
        'continue_treatment' => [
          ["",""],
          ["Yes", "YES"],
          ["DHO Dot site","DHO DOT SITE"],
          ["Transfer Out", "TRANSFER OUT"]
      ],
        'hiv_status' => [
          ['',''],
          ['Negative','NEGATIVE'],
          ['Positive','POSITIVE'],
          ['Unknown','UNKNOWN']
      ],
      'who_stage1' => [
        ['',''],
        ['Asymptomatic','ASYMPTOMATIC'],
        ['Persistent generalised lymphadenopathy','PERSISTENT GENERALISED LYMPHADENOPATHY'],
        ['Unspecified stage 1 condition','UNSPECIFIED STAGE 1 CONDITION']
      ],
      'who_stage2' => [
        ['',''],
        ['Unspecified stage 2 condition','UNSPECIFIED STAGE 2 CONDITION'],
        ['Angular cheilitis','ANGULAR CHEILITIS'],
        ['Popular pruritic eruptions / Fungal nail infections','POPULAR PRURITIC ERUPTIONS / FUNGAL NAIL INFECTIONS']
      ],
      'who_stage3' => [
        ['',''],
        ['Oral candidiasis','ORAL CANDIDIASIS'],
        ['Oral hairly leukoplakia','ORAL HAIRLY LEUKOPLAKIA'],
        ['Pulmonary tuberculosis','PULMONARY TUBERCULOSIS'],
        ['Unspecified stage 3 condition','UNSPECIFIED STAGE 3 CONDITION']
      ],
      'who_stage4' => [
        ['',''],
        ['Toxaplasmosis of the brain','TOXAPLASMOSIS OF THE BRAIN'],
        ["Kaposi's Sarcoma","KAPOSI'S SARCOMA"],
        ['Unspecified stage 4 condition','UNSPECIFIED STAGE 4 CONDITION'],
        ['HIV encephalopathy','HIV ENCEPHALOPATHY']
      ],
      'tb_clinical_symptoms' => [
        ['',''],
        ['Cough for the past 3 weeks','COUGH OVER 2 WKS'],
        ["Productive cough","PRODUCTIVE COUGH"],
        ['Unintentional weight loss',''],
        ['Night sweat','NIGHT SWEATS'],
        ['Loss of appetite','LOSS OF APPETITE'],
        ['Persistent fever',''],
        ['Shortness of breath','SHORTNESS OF BREATH'],
        ['Fatigue','FATIGUE'],
        ['Chest pains','CHEST PAIN']
      ],
      'tb_xray_interpretation' => [
        ['',''],
        ['Consistent of TB',''],
        ['Not Consistent of TB','']
      ],
      'dot_options' => [
        ['',''],
        ['Hospital','HOSPITAL'],
        ['Health Center','HEALTH CENTER'],
        ['Guardian','GUARDIAN']
      ],
      'cough_durations' => [
        ['',''],
        ['2 Weeks','WEEKS'],
        ['3 Weeks','WEEKS'],
        ['4 Weeks','WEEKS'],
        ['5 Weeks','WEEKS'],
        ['6 Weeks','WEEKS'],
        ['7 Weeks','WEEKS']
      ],
      'tb_types' => [
        ['',''],
        ['PTB','PTB'],
        ['EPTB','EPTB']
      ],
      'eptb_classification' => [
        ['',''],
        ['Pleural Effusion','PLEURAL EFFUSION'],
        ['Lymphadenopathy','LYMPHADENOPATHY'],
        ['Pericardial Effusion','PERICARDIAL EFFUSION'],
        ['Ascites','ASCITES'],
        ['Spinal / Bone disease','SPINAL DISEASE'],
        ['Meningitis','MENINGITIS']
      ],
      'tb_classification' => [
        ['',''],
        ['Susceptible','SUSCEPTIBLE TO TUBERCULOSIS DRU'],
        ['MDR','MDR-TB'],
        ['XDR','XDR TB']
      ],
      'patient_category' => [
        ['',''],
        ['New','NEW PATIENT'],
        ['Relapse','RELAPSE MDR-TB PATIENT'],
        ['Treatment after Default','TREATMENT AFTER DEFAULT MDR-TB PATIENT'],
        ['Fail','FAILED - TB'],
        ['Other','']
      ],
      'lab_orders' =>{
        "Blood" => ["Full blood count", "Malaria parasite", "Group & cross match", "Urea & Electrolytes", "CD4 count", "Resistance",
            "Viral Load", "Cryptococcal Antigen", "Lactate", "Fasting blood sugar", "Random blood sugar", "Sugar profile",
            "Liver function test", "Hepatitis test", "Sickling test", "ESR", "Culture & sensitivity", "Widal test", "ELISA",
            "ASO titre", "Rheumatoid factor", "Cholesterol", "Triglycerides", "Calcium", "Creatinine", "VDRL", "Direct Coombs",
            "Indirect Coombs", "Blood Test NOS"],
        "CSF" => ["Full CSF analysis", "Indian ink", "Protein & sugar", "White cell count", "Culture & sensitivity"],
        "Urine" => ["Urine microscopy", "Urinanalysis", "Culture & sensitivity"],
        "Aspirate" => ["Full aspirate analysis"],
        "Stool" => ["Full stool analysis", "Culture & sensitivity"],
        "Sputum" => ["AAFB(1st)", "AAFB(2nd)", "AAFB(3rd)", "Culture"],
        "Swab" => ["Microscopy", "Culture & sensitivity"]
      }
    }
  end

end

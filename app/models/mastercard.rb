class Mastercard 

 attr_accessor :date, :weight, :height, :bmi, :outcome, :reg, :s_eff, :sk , :pn, :hp, :pills, :gave, :cpt, :cd4,:estimated_date,:next_app, :tb_status, :doses_missed, :visit_by, :date_of_outcome, :reg_type, :adherence, :patient_visits, :sputum_count, :end_date, :art_status, :encounter_id 

 attr_accessor :patient_id,:arv_number, :national_id ,:name ,:age ,:sex, :init_wt, :init_ht ,:init_bmi ,:transfer_in ,:address, :landmark, :occupation, :guardian, :agrees_to_followup, :hiv_test_location, :hiv_test_date, :reason_for_art_eligibility, :date_of_first_line_regimen ,:tb_within_last_two_yrs, :eptb ,:ks,:pulmonary_tb


  def self.demographics(patient_obj)
    visits = self.new()
    person_demographics = patient_obj.person.demographics

    
    visits.patient_id = patient_obj.id
    visits.address = person_demographics['person']['addresses']['city_village']
    visits.national_id = person_demographics['person']['patient']['identifiers']['National id']
    visits.name = person_demographics['person']['names']['given_name'] + ' ' + person_demographics['person']['names']['family_name'] rescue nil
    visits.sex = person_demographics['person']['gender']
    visits.age =patient_obj.person.age
    visits.occupation = person_demographics['person']['occupation']
    visits.address = person_demographics['person']['addresses']['city_village']
    visits.landmark = person_demographics['person']['addresses']['location']
    visits.init_wt = patient_obj.initial_weight
    visits.init_ht = patient_obj.initial_height
    visits.bmi = patient_obj.initial_bmi
    visits.agrees_to_followup = patient_obj.person.observations.recent(1).question("Agrees to followup").all rescue nil
    visits.agrees_to_followup = visits.agrees_to_followup.to_s.split(':')[1].strip rescue nil
    visits.hiv_test_date = patient_obj.person.observations.recent(1).question("FIRST POSITIVE HIV TEST DATE").all rescue nil
    visits.hiv_test_date = visits.hiv_test_date.to_s.split(':')[1].strip rescue nil
    visits.hiv_test_location = patient_obj.person.observations.recent(1).question("FIRST POSITIVE HIV TEST LOCATION").all rescue nil
    visits.hiv_test_location = visits.hiv_test_location.to_s.split(':')[1].strip rescue nil
    visits.guardian = patient_obj.person.relationships.map{|r|Person.find(r.person_b).name}.join(' : ') rescue 'NONE'
    visits.reason_for_art_eligibility = patient_obj.person.observations.recent(1).question("REASON FOR ART ELIGIBILITY").all rescue nil
    visits.reason_for_art_eligibility = visits.reason_for_art_eligibility.to_s.split(':')[1].strip rescue nil

    treatment_encounter = Encounter.find(:first,
                                          :joins => "INNER JOIN orders ON encounter.encounter_id = orders.encounter_id",
                                          :conditions =>["encounter_type=? AND encounter.patient_id = ? AND concept_id = ? AND encounter.voided = 0",
                           EncounterType.find_by_name('TREATMENT').id,patient_obj.id,
                           ConceptName.find_by_name('STAVUDINE LAMIVUDINE AND NEVIRAPINE').concept_id],:order =>"encounter_datetime")

    if treatment_encounter
      drugs = []
      treatment_encounter.orders.map{|order|
        drugs << Drug.find(order.drug_order.drug_inventory_id) unless order.drug_order.quantity == 0
        drugs.map do |drug|
          visits.date_of_first_line_regimen = treatment_encounter.encounter_datetime.to_date if drug.arv?
        end
      }.compact
    end

    ans = ["EXTRAPULMONARY TUBERCULOSIS (EPTB)","PULMONARY TUBERCULOSIS WITHIN THE LAST 2 YEARS","PULMONARY TUBERCULOSIS","KAPOSIS SARCOMA"]
    staging_ans = patient_obj.person.observations.recent(1).question("WHO STG CRIT").all

    visits.ks = 'Yes' if staging_ans.map{|obs|ConceptName.find(obs.value_coded_name_id).name}.include?(ans[3])
    visits.tb_within_last_two_yrs = 'Yes' if staging_ans.map{|obs|ConceptName.find(obs.value_coded_name_id).name}.include?(ans[1])
    visits.eptb = 'Yes' if staging_ans.map{|obs|ConceptName.find(obs.value_coded_name_id).name}.include?(ans[0])
    visits.pulmonary_tb = 'Yes' if staging_ans.map{|obs|ConceptName.find(obs.value_coded_name_id).name}.include?(ans[2])
=begin

    #visits.arv_number = patient_obj.ARV_national_id
    visits.transfer =  patient_obj.transfer_in? ? "Yes" : "No"
=end
    visits
  end

  def self.visits(patient_obj)
    patient_visits = {}
    yes = ConceptName.find_by_name("YES")
    observations = Observation.find(:all,:conditions =>["voided = 0 AND person_id = ?",patient_obj.patient_id],:order =>"obs_datetime")
    ["HEIGHT","WEIGHT","REGIMEN","OUTCOME","TB STATUS","SYMPTOMS","VISIT","BMI","PILLS BROUGHT"].map do |field|
      observations.map do |obs|
         visit_date = obs.obs_datetime.to_date
         patient_visits[visit_date] = self.new() if patient_visits[visit_date].blank?
         case field
          when 'HEIGHT'
            concept_name = obs.concept.name.name rescue nil
            next unless concept_name == 'HEIGHT (CM)'
            patient_visits[visit_date].height = obs.value_numeric
          when "WEIGHT"
            concept_name = obs.concept.name.name rescue []
            next unless concept_name == 'WEIGHT (KG)'
            patient_visits[visit_date].weight = obs.value_numeric
          when "BMI"
            concept_name = obs.concept.name.name rescue []
            next unless concept_name == 'BODY MASS INDEX, MEASURED'
            patient_visits[visit_date].bmi = obs.value_numeric
          when "VISIT"
            concept_name = obs.concept.name.name rescue []
            next unless concept_name == 'RESPONSIBLE PERSON PRESENT' or concept_name == 'PATIENT PRESENT FOR CONSULTATION'
            patient_visits[visit_date].visit_by = '' if patient_visits[visit_date].visit_by.blank?
            patient_visits[visit_date].visit_by+= "P" if concept_name == 'PATIENT PRESENT FOR CONSULTATION' and obs.value_coded == yes.concept_id
            patient_visits[visit_date].visit_by+= "G" if concept_name == 'RESPONSIBLE PERSON PRESENT' and !obs.value_text.blank?
          when "TB STATUS"
            concept_name = obs.concept.name.name rescue []
            next unless concept_name == 'TB STATUS'
            status = ConceptName.find(obs.value_coded_name_id).name rescue nil
            patient_visits[visit_date].tb_status = status
            patient_visits[visit_date].tb_status = 'noSup' if status == 'TB NOT SUSPECTED'
            patient_visits[visit_date].tb_status = 'sup' if status == 'TB SUSPECTED'
            patient_visits[visit_date].tb_status = 'noRx' if status == 'CONFIRMED TB NOT ON TREATMENT'
            patient_visits[visit_date].tb_status = 'Rx' if status == 'CONFIRMED TB ON TREATMENT'
          when "REGIMEN"
            concept_name = obs.concept.name.name rescue []
            next unless concept_name == 'AMOUNT DISPENSED'
            drugs_quantity = []
            drugs_quantity << [Drug.find(obs.order.drug_order.drug_inventory_id),obs.order.drug_order.quantity]
            next if drugs_quantity.blank?
            patient_visits[visit_date].reg =  drugs_quantity[0].first.concept.name.name
            drugs_quantity.map{|drug,quantity|
              patient_visits[visit_date].gave+="<br/>#{drug.name} (#{quantity})" unless patient_visits[visit_date].gave.blank?
              patient_visits[visit_date].gave = "#{drug.name} (#{quantity})" if patient_visits[visit_date].gave.blank?
            }
          when "OUTCOME"
          when "SYMPTOMS"
          when "PILLS BROUGHT"
            concept_name = obs.concept.name.name rescue []
            next unless concept_name == 'AMOUNT OF DRUG BROUGHT TO CLINIC'
            patient_visits[visit_date].pills = obs.value_numeric
         end
      end
    end
    patient_visits
  end

end 

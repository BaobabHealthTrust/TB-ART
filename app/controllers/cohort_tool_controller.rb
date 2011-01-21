class CohortToolController < ApplicationController
  
  def select
    @report_type = params[:report_type]
    @header = params[:report_type] + ' '
    generate_list_of_quarter(2006)
  end
  
  def generate_list_of_quarter(start_year)
      date_today = Time.new
      @quarters =['Cumulative']
      
      total_number_of_year_btn_start_and_end_year = date_today.year - start_year + 1
      quarter_year = date_today.year + 1
      total_possible_number_of_quarters = 4 * total_number_of_year_btn_start_and_end_year-1
      
      if Time.now.month.to_i < 4 then
         start_quarter = 3
         quarter_year-=1
      elsif Time.now.month.to_i < 7 then
         start_quarter = 2
         quarter_year-=1
      elsif Time.now.month.to_i < 10 then
         start_quarter = 1
         quarter_year-=1
      else
         start_quarter = 0
      end
            
      for i in start_quarter..total_possible_number_of_quarters
        if ((i%4) != 0)
          @quarters << 'Q' + "#{4-(i % 4)}" + ' ' + quarter_year.to_s
        else
          quarter_year -= 1
          @quarters << 'Q' + "#{4-(i % 4)}" + ' ' + quarter_year.to_s
        end
      end
  end
  
  def prescriptions_without_dispensations
      include_url_params_for_back_button 
      date_range = quarter_start_and_end_dates()
      start_date = date_range.to_s.split("split").first
      end_date = date_range.to_s.split("split").last
      prescriptions_without_dispensations_data = Order.find_by_sql(["select order_id, patient_id, date_created from orders 
                                                 where not exists (select * from obs where orders.order_id = obs.order_id and obs.concept_id = ?) and  
                                                 date_created >= ? and date_created <= ?", ConceptName.find_by_name('PILLS DISPENSED').concept_id,
                                                 start_date , end_date ])
       @report = []
       prescriptions_without_dispensations_data.each do |prescription|
         arv_number = PatientIdentifier.find(:first, :select => "identifier", 
                                               :conditions =>["patient_id = ? and identifier_type = ?", prescription[:patient_id],
                                               PatientIdentifierType.find_by_name('ARV Number').patient_identifier_type_id])
         national_id = PatientIdentifier.find(:first, :select => "identifier", 
                                               :conditions =>["patient_id = ? and identifier_type = ?", prescription[:patient_id],
                                               PatientIdentifierType.find_by_name('National id').patient_identifier_type_id])
         drug_name = Drug.find(DrugOrder.find(prescription[:order_id]).drug_inventory_id).name
         @report << [prescription[:patient_id].to_s, arv_number[:identifier].to_s, national_id[:identifier], 
                     prescription[:date_created].strftime("%Y-%m-%d %H:%M:%S") , drug_name]
        end
      render :layout => 'report'
  end
  
  def  dispensations_without_prescriptions
       include_url_params_for_back_button
       date_range = quarter_start_and_end_dates()
       start_date = date_range.to_s.split("split").first
       end_date = date_range.to_s.split("split").last
       dispensations_without_prescription_data = Observation.find(:all, :select =>  "person_id, value_drug, date_created", 
                                                              :conditions =>["order_id IS NULL and date_created >= ? and date_created <= ? and
                                                               concept_id = ?" ,start_date , end_date, 
                                                               ConceptName.find_by_name('PILLS DISPENSED').concept_id])
       @report = []
       dispensations_without_prescription_data.each do |dispensation|
       arv_number = PatientIdentifier.find(:first, :select => "identifier", 
                                           :conditions =>["patient_id = ? and identifier_type = ?", dispensation[:person_id],
                                           PatientIdentifierType.find_by_name('ARV Number').patient_identifier_type_id])
       national_id = PatientIdentifier.find(:first, :select => "identifier", 
                                           :conditions =>["patient_id = ? and identifier_type = ?", dispensation[:person_id],
                                           PatientIdentifierType.find_by_name('National id').patient_identifier_type_id]) 
       @report << [dispensation[:person_id].to_s, arv_number[:identifier].to_s, national_id[:identifier], 
                   dispensation[:date_created].strftime("%Y-%m-%d %H:%M:%S") , Drug.find(dispensation[:value_drug]).name]
       end
       render :layout => 'report'
  end
  
  def  patients_with_multiple_start_reasons
       include_url_params_for_back_button
       date_range = quarter_start_and_end_dates()
       start_date = date_range.to_s.split("split").first
       end_date = date_range.to_s.split("split").last
       ################################################TO DO
      patients_with_multiple_start_reasons_data = Observation.find_by_sql(["select person_id, concept_id, date_created, value_coded_name_id from obs
                                                 where (select COUNT(*) from obs k where k.concept_id = ? and k.person_id = obs.person_id) >= 1 and  
                                                 date_created >= ? and date_created <= ? and obs.concept_id = ?", 
                                                 ConceptName.find_by_name('REASON FOR ART ELIGIBILITY').concept_id, start_date , end_date,
                                                 ConceptName.find_by_name('REASON FOR ART ELIGIBILITY').concept_id ])
       @report = []
       national_id = {}
       arv_number = {}
       patients_with_multiple_start_reasons_data.each do |reason|
         arv_number = PatientIdentifier.find(:first, :select => "identifier", 
                                               :conditions =>["patient_id = ? and identifier_type = ?", reason[:person_id],
                                               PatientIdentifierType.find_by_name('ARV Number').patient_identifier_type_id]) || {}
         national_id = PatientIdentifier.find(:first, :select => "identifier", 
                                               :conditions =>["patient_id = ? and identifier_type = ?", reason[:person_id],
                                               PatientIdentifierType.find_by_name('National id').patient_identifier_type_id]) || {}
         @report << [reason[:person_id].to_s, arv_number[:identifier], national_id[:identifier], 
                     reason[:date_created].strftime("%Y-%m-%d %H:%M:%S") , ConceptName.find(reason[:value_coded_name_id]).name]
        end
       #############################################TO DO
        render :layout => 'report'
  end
  
  def out_of_range_arv_number
      @report = [] 
      include_url_params_for_back_button
      date_range = quarter_start_and_end_dates()
      start_date = date_range.to_s.split("split").first
      end_date = date_range.to_s.split("split").last
      patient_identifier_type_id = PatientIdentifierType.find_by_name('ARV Number').patient_identifier_type_id
      arv_start_number = params[:arv_start_number].to_i
      arv_end_number = params[:arv_end_number].to_i
      @out_of_range_arv_number_data = PatientIdentifier.find_by_sql(["SELECT patient_id, identifier, date_created FROM patient_identifier WHERE identifier_type = ? AND  identifier >= ?
                                                                      AND identifier <= ? AND (NOT EXISTS(SELECT * FROM patient_identifier WHERE 
                                                                      identifier_type = ? AND date_created >= ? AND date_created <= ?))",
                                                                      patient_identifier_type_id,  arv_start_number,  arv_end_number, 
                                                                      patient_identifier_type_id, start_date, end_date])     
      dob = Time.new
      age = 0
      @out_of_range_arv_number_data.each do |arv_num_data|
      name = PersonName.find_by_person_id(arv_num_data[:patient_id].to_i).given_name + " " +
             PersonName.find_by_person_id(arv_num_data[:patient_id].to_i).family_name
      gender = Person.find_by_person_id(arv_num_data[:patient_id].to_i).gender
      dob    = Person.find_by_person_id(arv_num_data[:patient_id].to_i).birthdate
      if !dob.nil? then
         age = (Time.now.to_i - dob.end_of_day.to_i)/31536000
      end
      national_id = PatientIdentifier.find(:first, :select => "identifier", 
                                               :conditions =>["patient_id = ? and identifier_type = ?", arv_num_data[:patient_id],
                                               PatientIdentifierType.find_by_name('National id').patient_identifier_type_id]) || {}
      @report <<[arv_num_data[:patient_id], arv_num_data[:identifier], name, 
                national_id[:identifier],gender,age,dob,arv_num_data[:date_created].strftime("%Y-%m-%d %H:%M:%S")]
      end
      render :layout => 'report'
  end
  
  def data_consistency_check
      include_url_params_for_back_button
      date_range = quarter_start_and_end_dates()
      start_date = date_range.to_s.split("split").first
      end_date = date_range.to_s.split("split").last
      
      
     @dead_patients_data = PatientIdentifier.find_by_sql(["      
                   SELECT dead.patient_id, dead.date_changed as dealth_date, living.date_changed
                   FROM
                          (SELECT dead_z.patient_program_id, dead_k.state, dead_z.patient_id, 
                                  dead_k.date_changed
                           FROM patient_state dead_k INNER JOIN patient_program dead_z 
                           ON   dead_k.patient_program_id = dead_z.patient_program_id
                           WHERE  EXISTS (SELECT * FROM program_workflow_state p WHERE dead_k.state = program_workflow_state_id and
                                          concept_id = 1742) ) dead, 
                          (SELECT living_z.patient_program_id, living_k.state, living_z.patient_id, living_k.date_changed  
                           FROM patient_state living_k INNER JOIN patient_program living_z
                           on living_k.patient_program_id = living_z.patient_program_id
                           WHERE  NOT EXISTS (SELECT * FROM program_workflow_state p WHERE living_k.state = program_workflow_state_id and
                                          concept_id = 1742)) living
                    WHERE living.patient_id = dead.patient_id and dead.date_changed < living.date_changed
                           "])
      @dead_patients_data.to_yaml
      @dead_patients_data  
      @male_patients_data
      @patients_drug_data
      @patients_date_data
      @checks = [['Dead patients with Visits', 0, 'view'],['Male patients with a pregnant observation', 0, 'view'],
                 ['Patients who moved from 2nd to 1st line drugs', 0, 'view'],['patients with start dates > first receive drug dates', 0, 'view']] 
  
      Render :layout => 'report'
  end
  
  def list
    @report = []
    include_url_params_for_back_button
    render :layout => 'report'
  end
  
  def quarter_start_and_end_dates()
      quarter_start = Time.new
      quarter_end  = Time.new
      quarter = params[:quarter].to_s.split(" ").first
      quarter_year = params[:quarter].to_s.split(" ").last
      
      case quarter
        when 'Q1'
          start_month = 1
          end_month = 3
        when 'Q2'
          start_month = 4
          end_month = 6
        when 'Q3'
          start_month = 7
          end_month = 9
        when 'Q4'
          start_month = 10
          end_month = 12
        when 'Cumulative'
           if Time.now.month.to_i >=1 and Time.now.month.to_i <= 3 then
                start_month = 1
                end_month = 3
           elsif Time.now.month.to_i >= 4 and Time.now.month.to_i <= 6 then
                start_month = 4
                end_month = 6
           elsif Time.now.month.to_i >= 7 and Time.now.month.to_i <= 9 then
                start_month = 7
                end_month = 9
           else
               start_month = 10
               end_month = 12
           end
           quarter_year = Time.now.year
           quarter_end = quarter_end.change(:year => quarter_year.to_i, :month => end_month.to_i, 
                                            :day => last_day_of_month(quarter_year.to_i, end_month.to_i)).end_of_day.strftime("%Y-%m-%d %H:%M:%S").to_s
           quarter_start = Date.new(1945,01,01).to_date
           return  quarter_start.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S").to_s + "split" + quarter_end.to_s
      end
      
      quarter_start = quarter_start.change(:year => quarter_year.to_i, :month => start_month.to_i,
                                         :day => 1).beginning_of_day.strftime("%Y-%m-%d %H:%M:%S").to_s
      
      quarter_end = quarter_end.change(:year => quarter_year.to_i, :month => end_month.to_i, 
                                        :day => last_day_of_month(quarter_year.to_i, end_month.to_i)).end_of_day.strftime("%Y-%m-%d %H:%M:%S").to_s
      quarter_start.to_s + "split" + quarter_end.to_s
  end
  
  def last_day_of_month(year, month_number)
        (Date.new(year,12,31).to_date<<(12-month_number)).day
  end
  
  def include_url_params_for_back_button
       @report_quarter = params[:quarter]
       @report_type = params[:report_type]
  end
  
end



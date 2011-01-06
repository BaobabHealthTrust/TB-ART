class CohortToolController < ApplicationController
  
  def select
    @report_type = params[:report_type]
    @header = params[:report_type] + ' '
    generate_list_of_quarter(2006)
    render :layout => "menu"
  end
  
  def generate_list_of_quarter(start_year)
      date_today = Time.new
      @quarters =['Cumulative']
      
      total_number_of_year_btn_start_and_end_year = date_today.year - start_year + 1
      quarter_year = date_today.year + 1
      total_possible_number_of_quarters = 4 * total_number_of_year_btn_start_and_end_year-1
      
      for i in 0..total_possible_number_of_quarters
        if ((i%4) != 0)
          @quarters << 'Q' + "#{(i % 4)+1}" + ' ' + quarter_year.to_s
        else
          quarter_year -= 1
          @quarters << 'Q' + "#{(i % 4) + 1}" + ' ' + quarter_year.to_s
        end
      end 
  end
  
  def prescriptions_without_dispensations
      date_range = quarter_start_and_end_dates()
      start_date = date_range.to_s.split("split").first
      end_date = date_range.to_s.split("split").last
      render :layout => 'report'
  end
  
  def  dispensations_without_prescriptions
       
       #These parameters are used by the mastercard go back to the report
       @report_quarter = params[:quarter]
       #########################################################
       
       date_range = quarter_start_and_end_dates()
       start_date = date_range.to_s.split("split").first
       end_date = date_range.to_s.split("split").last
       dispensations_without_prescription_data = Observation.find(:all, :select =>  "person_id, value_drug, date_created", 
                                                              :conditions =>["order_id IS NULL and date_created >= ? and date_created <= ? and
                                                               concept_id = 2834" ,start_date , end_date])
       @report = []
       dispensations_without_prescription_data.each do |dispensation|
       # @report format::: ID, ARVNumber, National_ID, Visit Date, Dispensed_Drug
       #raise PatientIdentifier.inspect
       arv_number = PatientIdentifier.find(:first, :select => "identifier", 
                                           :conditions =>["patient_id = ? and identifier_type = ?", dispensation[:person_id], '4'])
       national_id = PatientIdentifier.find(:first, :select => "identifier", 
                                           :conditions =>["patient_id = ? and identifier_type = ?", dispensation[:person_id], '3']) 
       @report << [dispensation[:person_id].to_s, arv_number[:identifier].to_s, national_id[:identifier], 
                   dispensation[:date_created].strftime("%Y-%m-%d %H:%M:%S") , Drug.find(dispensation[:value_drug]).name]
       end
       render :layout => 'report'
  end
  
  def  patients_with_multiple_start_reasons
       date_range = quarter_start_and_end_dates()
       start_date = date_range.to_s.split("split").first
       end_date = date_range.to_s.split("split").last
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
  
  
end



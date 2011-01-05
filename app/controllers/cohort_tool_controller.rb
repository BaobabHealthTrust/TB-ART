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
      @report_type = quarter_start_and_end_dates()
      render :layout => 'report'
  end
  
  def  dispensations_without_prescriptions
        @report_type = quarter_start_and_end_dates()
        render :layout => 'report'
  end
  
  def  patients_with_multiple_start_reasons
        @report_type = quarter_start_and_end_dates()
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
           return  quarter_start.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S").to_s + " " + quarter_end.to_s
      end
      
      quarter_start = quarter_start.change(:year => quarter_year.to_i, :month => start_month.to_i,
                                         :day => 1).beginning_of_day.strftime("%Y-%m-%d %H:%M:%S").to_s
      
      quarter_end = quarter_end.change(:year => quarter_year.to_i, :month => end_month.to_i, 
                                        :day => last_day_of_month(quarter_year.to_i, end_month.to_i)).end_of_day.strftime("%Y-%m-%d %H:%M:%S").to_s
      quarter_start.to_s + " " + quarter_end.to_s
  end
  
  def last_day_of_month(year, month_number)
        (Date.new(year,12,31).to_date<<(12-month_number)).day
  end
  
end



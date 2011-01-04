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
  
  def reports
  raise params[:report_type]
  end
  
  def prescriptions_without_dispensations
      @report_type = params[:quarter]
      render :layout => 'clinic'
  end
  
end



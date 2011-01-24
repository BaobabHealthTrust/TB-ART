class CohortToolController < ApplicationController

  def select
    @cohort_quarters = [""]
    @report_type     = params[:report_type]

    if @report_type == "in_arv_number_range"
      @arv_number_start = params[:arv_number_start]
      @arv_number_end   = params[:arv_number_end]
    end

  start_date  = Encounter.initial_encounter.encounter_datetime
  end_date    = Date.today

  @cohort_quarters  += Report.generate_cohort_quarters(start_date, end_date)
  end

  def reports
    session[:list_of_patients] = nil

    if params[:report]

      case  params[:report_type]
        when "visits_by_day"
          redirect_to :action   => "visits_by_day",
                      :name     => params[:report],
                      :pat_name => "Visits by day",
                      :quarter  => params[:report].gsub("_"," ")
        return

        when "non_eligible_patients_in_cohort"
          date = Report.generate_cohort_date_range(params[:report])

          redirect_to :action       => "cohort_debugger",
                      :controller   => "reports",
                      :start_date   => date.first.to_s,
                      :end_date     => date.last.to_s,
                      :id           => "start_reason_other",
                      :report_type  => "non_eligible patients in: #{params[:report]}"
        return

        when "in_arv_number_range"
          redirect_to :action           => "in_arv_number_range",
                      :arv_number_end   => params[:arv_number_end],
                      :arv_number_start => params[:arv_number_start],
                      :quarter          => params[:report].gsub("_"," ")
        return

        when "internal_consistency_checks"
          redirect_to :action => "internal_consistency_checks",
                      :quarter => params[:report].gsub("_"," ")
        return

        when "summary_of_records_that_were_updated"
          redirect_to :action   => "records_that_were_updated",
                      :quarter  => params[:report].gsub("_"," ")
        return

        when "adherence_histogram_for_all_patients_in_the_quarter"
          redirect_to :action   => "adherence",
                      :quarter  => params[:report].gsub("_"," ")
        return

        when "patients_with_adherence_greater_than_hundred"
          redirect_to :action  => "patients_with_adherence_greater_than_hundred",
                      :quarter => params[:report].gsub("_"," ")
        return

        when "patients_with_multiple_start_reasons"
          redirect_to :action       => "patients_with_multiple_start_reasons",
                      :quarter      => params[:report].gsub("_"," "),
                      :report_type  => params[:report_type]
        return

        when "dispensations_without_prescriptions"
          redirect_to :action       => "dispensations",
                      :quarter      => params[:report].gsub("_"," "),
                      :report_type  => params[:report_type]
        return

        when "prescriptions_without_dispensations"
          redirect_to :action       => "dispensations",
                      :quarter      => params[:report].gsub("_"," "),
                      :report_type  => params[:report_type]
        return

        when "drug_stock_report"
          start_date  = "#{params[:start_year]}-#{params[:start_month]}-#{params[:start_day]}"
          end_date    = "#{params[:end_year]}-#{params[:end_month]}-#{params[:end_day]}"

          if end_date.to_date < start_date.to_date
            redirect_to :controller   => "cohort_tool",
                        :action       => "select",
                        :report_type  =>"drug_stock_report" and return
          end rescue nil

          redirect_to :controller => "drug",
                      :action     => "report",
                      :start_date => start_date,
                      :end_date   => end_date,
                      :quarter    => params[:report].gsub("_"," ")
        return
      end
    end
  end

  def records_that_were_updated
    @quarter    = params[:quarter]

    date_range  = Report.generate_cohort_date_range(@quarter)
    @start_date = date_range.first
    @end_date   = date_range.last

    @encounters = CohortTool.records_that_were_updated(@quarter)

    render :layout => false
  end

  def visits_by_day
    encounters = CohortTool.visits_by_day(params[:quarter])
    data  = ""
    encounters.each{|x,y|data+="#{x}:#{y};"}
    visit_by_days = data[0..-2] || ''
    @results  = Report.stats_to_show(visit_by_days) unless visit_by_days.blank?
    @totals_by_week_day = CohortTool.totals_by_week_day(@results) unless @results.blank?
    @stats_name = "Visits by day"
    @quarter    = params[:quarter]
    render :layout => false
  end
end

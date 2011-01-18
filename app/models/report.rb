module Report
    def self.generate_cohort_date_range(quarter = "", start_date = nil, end_date = nil)

    quarter_beginning   = start_date.to_date  rescue nil
    quarter_ending      = end_date.to_date    rescue nil
    quarter_end_dates   = []
    quarter_start_dates = []
    date_range          = [nil, nil]

    if(!quarter_beginning.nil? && !quarter_ending.nil?)
      date_range = [quarter_beginning, quarter_ending]
		elsif (!quarter.nil? && quarter == "cumulative")
      quarter_beginning = Encounter.initial_encounter.encounter_datetime.to_date
      quarter_ending    = Date.today.to_date

      date_range        = [quarter_beginning, quarter_ending]
		elsif(!quarter.nil? && (/Q[1-4][\_\+\- ]\d\d\d\d/.match(quarter)))
			quarter, quarter_year = quarter.humanize.split(" ")

      quarter_start_dates = ["#{quarter_year}-01-01".to_date, "#{quarter_year}-04-01".to_date, "#{quarter_year}-07-01".to_date, "#{quarter_year}-10-01".to_date]
      quarter_end_dates   = ["#{quarter_year}-03-31".to_date, "#{quarter_year}-06-30".to_date, "#{quarter_year}-09-30".to_date, "#{quarter_year}-12-31".to_date]

      current_quarter   = (quarter.match(/\d+/).to_s.to_i - 1)
      quarter_beginning = quarter_start_dates[current_quarter]
      quarter_ending    = quarter_end_dates[current_quarter]

      date_range = [quarter_beginning, quarter_ending]

    end

    return date_range
  end

end

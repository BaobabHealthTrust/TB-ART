class CohortToolController < ApplicationController

  def select
    @report_type = params[:report_type]

    if @report_type == "in_arv_number_range"
      @arv_number_start = params[:arv_number_start]
      @arv_number_end   = params[:arv_number_end]
    end
  end

end

class EncounterTypesController < ApplicationController

  def index
    if GlobalProperty.use_user_selected_activities
      redirect_to "/user/activities?patient_id=#{params[:patient_id]}"
    end
    # TODO add clever sorting
    @encounter_types = EncounterType.find(:all).map{|enc|enc.name.gsub(/.*\//,"").gsub(/\..*/,"").humanize}
    @available_encounter_types = Dir.glob(RAILS_ROOT+"/app/views/encounters/*.rhtml").map{|file|file.gsub(/.*\//,"").gsub(/\..*/,"").humanize}
    @available_encounter_types -= @available_encounter_types - @encounter_types
  end

  def show
    redirect_to "/prescriptions/tb_treatment?patient_id=#{params[:patient_id]}" and return if params[:encounter_type] == 'TB Treatment'
    redirect_to "/encounters/new/#{params["encounter_type"].downcase.gsub(/ /,"_")}?#{params.to_param}" and return
  end

end

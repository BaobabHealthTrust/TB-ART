class EncounterTypesController < ApplicationController

  def index
    # TODO add clever sorting
    #@encounter_types = EncounterType.find(:all).map{|enc|enc.name.gsub(/.*\//,"").gsub(/\..*/,"").humanize}
    #@available_encounter_types = Dir.glob(RAILS_ROOT+"/app/views/encounters/*.rhtml").map{|file|file.gsub(/.*\//,"").gsub(/\..*/,"").humanize}
    #@available_encounter_types -= @available_encounter_types - @encounter_types
    @available_encounter_types = GlobalProperty.find_by_property("statistics.show_encounter_types").property_value.split(',') rescue EncounterType.find(:all).map{|enc|enc.name.gsub(/.*\//,"").gsub(/\..*/,"").humanize}
  end

  def show
    redirect_to "/encounters/new/#{params["encounter_type"].downcase.gsub(/ /,"_")}?#{params.to_param}" and return
  end

end

class EncounterTypesController < ApplicationController

  def index
    # TODO add clever sorting
    location = Location.find(session[:location_id]).name
    @available_encounter_types = ['Update HIV Status', 'Lab'] if location == 'Chronic Cough'
    @available_encounter_types = ['TB Reception', 'Update HIV Status', 'ART Enrollment', 'Vitals'] if location == 'TB Reception'
    @available_encounter_types = ['TB Clinic Visit', 'llh Staging'] if location == 'TB Clinician Station'
    @available_encounter_types = ['TB Registration', 'TB Treatment'] if location == 'TB Registration'
    @available_encounter_types = ['TB Treatment'] if location == 'TB Folloup Room'
    @available_encounter_types = ['Give Drugs'] if location == 'Pharmacy'
    #@encounter_types = EncounterType.find(:all).map{|enc|enc.name.gsub(/.*\//,"").gsub(/\..*/,"").humanize}
    #@available_encounter_types = Dir.glob(RAILS_ROOT+"/app/views/encounters/*.rhtml").map{|file|file.gsub(/.*\//,"").gsub(/\..*/,"").humanize}
    #@available_encounter_types -= @available_encounter_types - @encounter_types

    #@available_encounter_types = GlobalProperty.find_by_property("statistics.show_encounter_types").property_value.split(',') rescue EncounterType.find(:all).map{|enc|enc.name.gsub(/.*\//,"").gsub(/\..*/,"").humanize}
    #@available_encounter_types = ['TB Reception', 'Update HIV Status', 'ART Enrollment', 'Vitals'] if location == 'TB Reception'
  end

  def show
    redirect_to "/encounters/new/#{params["encounter_type"].downcase.gsub(/ /,"_")}?#{params.to_param}" and return
  end

end

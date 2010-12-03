class PatientsController < ApplicationController
  before_filter :find_patient, :except => [:void]
  
  def show
    @encounters = @patient.encounters.current.find(:all)
    @prescriptions = @patient.orders.unfinished.prescriptions.all
    @programs = @patient.patient_programs.all
    # This code is pretty hacky at the moment
    @restricted = ProgramLocationRestriction.all(:conditions => {:location_id => Location.current_location.location_id})
    @restricted.each do |restriction|    
      @encounters = restriction.filter_encounters(@encounters)
      @prescriptions = restriction.filter_orders(@prescriptions)
      @programs = restriction.filter_programs(@programs)
    end
    render :template => 'dashboards/overview', :layout => 'dashboard' 
  end

  def treatment
    @prescriptions = @patient.orders.current.prescriptions.all
    @historical = @patient.orders.historical.prescriptions.all
    @restricted = ProgramLocationRestriction.all(:conditions => {:location_id => Location.current_location.location_id})
    @restricted.each do |restriction|
      @prescriptions = restriction.filter_orders(@prescriptions)
      @historical = restriction.filter_orders(@historical)
    end
    render :template => 'dashboards/treatment', :layout => 'dashboard' 
  end

  def relationships
    @relationships = @patient.relationships rescue []
    @restricted = ProgramLocationRestriction.all(:conditions => {:location_id => Location.current_location.location_id})
    @restricted.each do |restriction|
      @relationships = restriction.filter_relationships(@relationships)
    end
    render :template => 'dashboards/relationships', :layout => 'dashboard' 
  end

  def problems
    render :template => 'dashboards/problems', :layout => 'dashboard' 
  end

  def personal
    render :template => 'dashboards/personal', :layout => 'dashboard' 
  end

  def history
    render :template => 'dashboards/history', :layout => 'dashboard' 
  end

  def programs
    @programs = @patient.patient_programs.all
    @restricted = ProgramLocationRestriction.all(:conditions => {:location_id => Location.current_location.location_id})
    @restricted.each do |restriction|
      @programs = restriction.filter_programs(@programs)
    end
    render :template => 'dashboards/programs', :layout => 'dashboard' 
  end

  def graph
    render :template => "graphs/#{params[:data]}", :layout => false 
  end

  def void 
    @encounter = Encounter.find(params[:encounter_id])
    @encounter.void
    show and return
  end
  
  def print_registration
    print_and_redirect("/patients/national_id_label/?patient_id=#{@patient.id}", next_task(@patient))  
  end
  
  def print_visit
    print_and_redirect("/patients/visit_label/?patient_id=#{@patient.id}", next_task(@patient))  
  end
  
  def national_id_label
    print_string = @patient.national_id_label rescue (raise "Unable to find patient (#{params[:patient_id]}) or generate a national id label for that patient")
    send_data(print_string,:type=>"application/label; charset=utf-8", :stream=> false, :filename=>"#{params[:patient_id]}#{rand(10000)}.lbl", :disposition => "inline")
  end
  
  def visit_label
    print_string = @patient.visit_label rescue (raise "Unable to find patient (#{params[:patient_id]}) or generate a visit label for that patient")
    send_data(print_string,:type=>"application/label; charset=utf-8", :stream=> false, :filename=>"#{params[:patient_id]}#{rand(10000)}.lbl", :disposition => "inline")
  end

  def mastercard
    @patient_id = params[:patient_id] 
    render :layout => "menu"
  end
  
private
  
  
end

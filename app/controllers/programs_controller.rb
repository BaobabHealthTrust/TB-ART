class ProgramsController < ApplicationController
  before_filter :find_patient, :except => [:void, :states]
  
  def new
    session[:return_to] = nil
    session[:return_to] = params[:return_to] unless params[:return_to].blank?
    @patient_program = PatientProgram.new
  end

  def create
    @patient_program = @patient.patient_programs.build(
      :program_id => params[:program_id],
      :date_enrolled => params[:initial_date],
      :location_id => params[:location_id])      
    @patient_state = @patient_program.patient_states.build(
      :state => params[:initial_state],
      :start_date => params[:initial_date]) 
    if @patient_program.save && @patient_state.save
      redirect_to session[:return_to] and return unless session[:return_to].blank?
      redirect_to :controller => :patients, :action => :programs, :patient_id => @patient.patient_id
    else 
      flash.now[:error] = @patient_program.errors.full_messages.join(". ")
      render :action => "new"
    end
  end

  def status
    @program = PatientProgram.find(params[:id])
    render :layout => false    
  end
  
  def void
    @program = PatientProgram.find(params[:id])
    @program.void
    head :ok
  end  
  
  def locations
    @locations = Location.most_common_program_locations(params[:q] || '')
    @names = @locations.map{|location| "<li value='#{location.location_id}'>#{location.name}</li>" }
    render :text => @names.join('')
  end
  
  def workflows
    @workflows = ProgramWorkflow.all(:conditions => ['program_id = ?', params[:program]], :include => :concept)
    @names = @workflows.map{|workflow| "<li value='#{workflow.id}'>#{workflow.concept.name.name}</li>" }
    render :text => @names.join('')
  end
  
  def states
    @states = ProgramWorkflowState.all(:conditions => ['program_workflow_id = ?', params[:workflow]], :include => :concept)
    @names = @states.map{|state| "<li value='#{state.id}'>#{state.concept.name.name}</li>" }
    render :text => @names.join('')  
  end
end

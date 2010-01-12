class ProgramsController < ApplicationController
  before_filter :find_patient, :except => [:void, :states]
  
  def new
    @patient_program = PatientProgram.new
  end

  def create
    @patient_program = @patient.patient_programs.build(params[:patient_program])
    if @patient_program.save
      redirect_to :controller => :patients, :action => :programs, :patient_id => @patient.patient_id
    else 
      render :action => "new" 
    end
  end

  def states
    @program = PatientProgram.find(params[:id])
    render :layout => false    
  end
  
  def void
    @program = PatientProgram.find(params[:id])
    @program.void!
    head :ok
  end  
  
  def locations
    @locations = Location.most_common_program_locations(params[:q] || '')
    @names = @locations.map{|location| "<li value='#{location.id}'>#{location.name}</li>" }
    render :text => @names.join('')
  end
  
  def workflows
    @workflows = ProgramWorkflow.active.all(:conditions => ['program_id = ?', params[:program]], :include => :concept)
    @names = @workflows.map{|workflow| "<li value='#{workflow.id}'>#{workflow.concept.name.name}</li>" }
    render :text => @names.join('')
  end
  
  def states
    @states = ProgramWorkflowState.active.all(:conditions => ['program_workflow_id = ?', params[:workflow]], :include => :concept)
    @names = @states.map{|state| "<li value='#{state.id}'>#{state.concept.name.name}</li>" }
    render :text => @names.join('')  
  end
end

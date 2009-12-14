class ProgramsController < ApplicationController
  before_filter :find_patient, :except => [:void]
  
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
  
  def void
    @program = PatientProgram.find(params[:id])
    @program.void!
    head :ok
  end  
end

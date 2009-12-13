class RelationshipsController < ApplicationController
  before_filter :find_patient
  
  def new
    render :layout => 'application'
  end

  def search
    render :layout => 'relationships'
  end
  
  def create
    @relationship = Relationship.new(
      :person_a => @patient.patient_id,
      :person_b => params[:relation],
      :relationship => params[:relationship])
    if @relationship.save
      redirect_to :controller => :patients, :action => :relationships, :patient_id => @patient.patient_id
    else 
      render :action => "new" 
    end
  end
  
  def void
    @relationship = Relationship.find(params[:id])
    @relationship.void!
    head :ok
  end
  
private
  def find_patient
    @patient = Patient.find(params[:patient_id] || session[:patient_id]) rescue nil
  end
end

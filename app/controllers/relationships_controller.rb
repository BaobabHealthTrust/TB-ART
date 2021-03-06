class RelationshipsController < ApplicationController
  before_filter :find_patient, :except => [:void]
  
  def new
    render :layout => 'application'
    # render :template => 'dashboards/relationships_dashboard', :layout => false
  end

  def search
    session[:return_to] = nil
    session[:return_to] = params[:return_to] unless params[:return_to].blank?
    session[:guardian_added] = nil
    session[:guardian_added] = params[:guardian_added] unless params[:guardian_added].blank?
    render :layout => 'relationships'
  end
  
  def create
    @relationship = Relationship.new(
      :person_a => @patient.patient_id,
      :person_b => params[:relation],
      :relationship => params[:relationship])
    if @relationship.save
      redirect_to session[:return_to] and return unless session[:return_to].blank?
      redirect_to :controller => :patients, :action => :guardians_dashboard, :patient_id => @patient.patient_id
    else 
      render :action => "new" 
    end
  end
  
  def void
    @relationship = Relationship.find(params[:id])
    @relationship.void
    head :ok
  end  
end

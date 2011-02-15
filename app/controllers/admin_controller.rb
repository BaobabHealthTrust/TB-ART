class AdminController < ApplicationController
  before_filter :require_admin
  
  def index
    render :layout => "menu"
  end
  
  def set_datetime
    # set for 1 second after midnight to designate it as a retrospective date
    session[:datetime] = Time.mktime(params[:set_year].to_i,params[:set_month].to_i,params[:set_day].to_i,0,0,1) 
    redirect_to '/clinic'
  end
  
  def reset_datetime
    # reset the session date to nil - start using the system curr date
    session[:datetime] = nil
    redirect_to '/clinic'
  end

  def move_everything_to_previous_day
    # CAREFUL: Only for testing purpose once you know what you do
    # This changes datetime for previous stuff
    sql="update encounter set encounter_datetime = (date_sub(encounter_datetime, interval 1 day));"
    ActiveRecord::Base.connection.execute(sql)     
    sql="update obs set obs_datetime = (date_sub(obs_datetime, interval 1 day));"
    ActiveRecord::Base.connection.execute(sql) 
    sql="update orders set start_date = (date_sub(start_date, interval 1 day));"
    ActiveRecord::Base.connection.execute(sql) 
    sql="update patient_program set date_enrolled = (date_sub(date_enrolled, interval 1 day));" # date_completed?
    ActiveRecord::Base.connection.execute(sql) 
    sql="update patient_state set start_date = (date_sub(start_date, interval 1 day));" # end_date?
    ActiveRecord::Base.connection.execute(sql) 
    
    redirect_to '/clinic'
  end
  
private
  
  def require_admin
    unless current_user.admin?
      flash[:error] = "You must be an admin to view the admin page"
      redirect_to '/'
    end  
  end
end

class PersonAddressesController < ApplicationController
  def village
    search("city_village", params[:search_string])
  end

  def traditional_authority
    search("county_district", params[:search_string])
  end
  
  def landmark
    search("address1", params[:search_string])
  end

  def address2
    search("address2", params[:search_string])
  end

  def search(field_name, search_string)
    @names = PersonAddress.find_most_common(field_name, search_string).collect{|person_name| person_name.send(field_name)}
    render :text => "<li>" + @names.join("</li><li>") + "</li>"
    #redirect_to :action => :new, :address2 => params[:address2]
  end

  def current_residence
    search_location(params[:search_string])
  end

    def search_location(search_string)

    @areas = Location.areas.grep(/#{search_string}/i).compact.sort_by{|area| area.split(" ")[1].to_i}[0..40]

    @results = @areas + Location.current_residences.grep(/#{search_string}/i).compact.sort_by{|location|
      location.index(/#{search_string}/) || 100 # if the search string isn't found use value 100
    }[0..10]

    render :text => @results.collect{|location|"<li>#{location}</li>"}.join("\n")
  end
end

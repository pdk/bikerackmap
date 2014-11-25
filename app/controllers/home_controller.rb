class HomeController < ApplicationController
  def index
    render :layout => false
  end
  
  def map
    render :layout => false
  end

  def geohash
    g = params[:geohash_string]
    if g.nil?
      redirect_to :map_page_path
    else
      render :layout => false
    end
  end

end

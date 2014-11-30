class HomeController < ApplicationController
  def index
    render :layout => false
  end
  
  def map
    render :layout => false
  end

  def geohash
    g = params[:geohash_string]
    render :layout => false
  end

  def show
  end

end

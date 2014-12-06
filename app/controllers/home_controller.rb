class HomeController < ApplicationController
  layout "home"
  
  def index
  end
  
  def map
  end

  def geohash
    g = params[:geohash_string]
  end

  def show
  end

  def about
  end
end

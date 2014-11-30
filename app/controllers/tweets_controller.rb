class TweetsController < ApplicationController
  def new
  end

  def create
    current_user.tweet(params[:tweet][:message])
  end

end

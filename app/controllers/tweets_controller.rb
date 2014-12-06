class TweetsController < ApplicationController
  def new
  end

  def save_photo(photo)
    return nil if photo.blank?
    
    # It's not clear that we really need to 'save' the uploaded
    # images in order to post them to twitter. Eventually we'll
    # need to clean this up, but I just feel better somehow
    # knowing that there is a copy here.
    
    filename = photo.original_filename
    rand_subdir = (rand(500) + 100).to_s
    directory = "public/images/upload/#{current_user.provider}/#{current_user.uid}/#{rand_subdir}/"
    FileUtils.mkdir_p(directory)
    path = File.join(directory, filename)
    File.open(path, "wb") { |f|
      f.write(photo.read)
    }
    
    return path
  end

  def create
    photo_list = []
    photo_list << save_photo(params[:tweet][:photo_one]) if params[:tweet][:photo_one].present?
    photo_list << save_photo(params[:tweet][:photo_two]) if params[:tweet][:photo_two].present?

    message = params[:tweet][:message]
    geohash = params[:tweet][:geohash]

    at_name = "@bicyclerackkk"

    if message.blank?
      message = "here is a #{at_name} http://bikerackmap.com/g/#{geohash}"
    elsif message.include? at_name
      message = "#{message} http://bikerackmap.com/g/#{geohash}"
    else
      message = "#{at_name} #{message} http://bikerackmap.com/g/#{geohash}"
    end

    if photo_list.present?
      media_list = photo_list.map { |filename| File.new(filename) }
      current_user.twitter_client.update_with_media(message, media_list)
    else
      current_user.twitter_client.update(message)
    end
  
    @message = message
    @geohash = geohash
    
    render :layout => "home"
  end

end

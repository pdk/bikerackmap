class QueryController < ApplicationController
  def index
    @tweet_data = []
    Tweet.where(:lat.exists => true).each do |t|
      n = {}
      n['created_at'] = t.data['created_at']
      n['id'] = t.id_str
      n['text'] = t.data['text']
      n['user'] = { :screen_name => t.data['user']['screen_name'] }
      n['coordinates'] = { :coordinates => [ t.long, t.lat ]}
      n['entities'] = {
        :media => [ {
           :media_url => t.data.try(:[], 'entities').try(:[], :media).try(:[], 0).try(:[], :media_url),
           :url => t.data.try(:[], 'entities').try(:[], :media).try(:[],0).try(:[], :url)
         }]}
      @tweet_data << n
    end
    
    respond_to do |format|
      format.json {
        render :json => @tweet_data
      }
    end
  end
end

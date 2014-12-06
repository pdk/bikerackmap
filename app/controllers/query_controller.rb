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
  
  
  def mapped_tweets
    data = {
      'type'      => 'FeatureCollection',
      'features'  => []
    }
  
    Tweet.where(:lat.exists => true).each do |t|
      data['features'] << {
        'type' => 'Feature',
        'properties' => {
          'title'           => t.data['text'],
          'marker-color'    => '#393',
          'marker-size'     => 'large',
          'marker-symbol'   => 'bicycle',
          'url'             => %{http://twitter.com/#{t.data['user']['screen_name']}/status/#{t.id_str}}
        },
        geometry: {
            type: 'Point',
            coordinates: [t.long, t.lat]
        }        
      }
    end
  
    respond_to do |format|
      format.json {
        render :json => data
      }
    end
  end
end

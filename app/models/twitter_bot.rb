class TwitterBot
  
  def TwitterBot.rest_client
    Twitter::REST::Client.new do |config|
      config.consumer_key =         ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret =      ENV['TWITTER_CONSUMER_SECRET']
      config.access_token =         ENV['TWITTER_OAUTH_TOKEN']
      config.access_token_secret =  ENV['TWITTER_OAUTH_TOKEN_SECRET']
    end
  end

  def TwitterBot.streaming_client
    Twitter::Streaming::Client.new do |config|
      config.consumer_key =         ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret =      ENV['TWITTER_CONSUMER_SECRET']
      config.access_token =         ENV['TWITTER_OAUTH_TOKEN']
      config.access_token_secret =  ENV['TWITTER_OAUTH_TOKEN_SECRET']
    end
  end

  def TwitterBot.reload_all_mentions
    # first tweet @bicyclerack: https://twitter.com/phlatphrog/status/181524058561716225
    rest_client.mentions_timeline(:since_id => "181524058561716224", :count => 200).each do |t|
      Tweet.insert_tweet(t)
    end
  end

  def TwitterBot.load_new_mentions
    last_id_str = Tweet.maximum(:id_str)
    rest_client.mentions_timeline(:since_id => last_id_str).each do |t|
      Tweet.insert_tweet(t)
    end
  end

  def TwitterBot.capture_stream
    streaming_client.user(:with => "user") do |t|
      case t
      when Twitter::Tweet
        puts "====== new tweet ======"
        puts t.to_json
        Tweet.insert_tweet(t)
        
      when Twitter::DirectMessage
        puts "It's a direct message!"
        
      when Twitter::Streaming::StallWarning
        warn "Falling behind!"
        
      when Twitter::Streaming::Event
        # Played around here a bit and was not able to 
        # generate a delete event for current stream 
        # configuration. A small bit of googling
        # did not reveal how to get these, but it did
        # show that other people are failing to get
        # them.        
        
        data = Oj.load(t.to_json)
        puts "===== Streaming Event ====="
        puts data
        # sample delete:
        # {
        #   "delete":{
        #     "status":{
        #       "id":1234,
        #       "id_str":"1234",
        #       "user_id":3,
        #       "user_id_str":"3"
        #     }
        #   }
        # }
      end
    end
  end
end

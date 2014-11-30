class User
  include MongoMapper::Document

  key :provider, String
  key :uid, String
  key :name, String
  key :oauth_token, String
  key :oauth_secret, String

  key :twitter_handle, String
  key :twitter_location, String
  key :twitter_image, String
  key :twitter_description, String
  key :twitter_url, String

  User.ensure_index([[:provider, 1], [:uid, 1]], :unique => true)

  def User.from_omniauth(auth)
    # http://vcap.me:3000/auth/twitter/callback?oauth_token=2AYsOf5tLQCd2MwAGJ4ONdP2JnORw03O&oauth_verifier=KCF9yETy1cCPLotCU6sQumHQ0jOIwrwJ
    # {"oauth_token"=>"2AYsOf5tLQCd2MwAGJ4ONdP2JnORw03O",
    #  "oauth_verifier"=>"KCF9yETy1cCPLotCU6sQumHQ0jOIwrwJ",
    #  "provider"=>"twitter"}
    
    u = User.first_or_new({
      :provider     => auth.provider,
      :uid          => auth.uid
    })
      
    u.name                  = auth.info.name
    u.oauth_token           = auth.credentials.token
    u.oauth_secret          = auth.credentials.secret
    u.twitter_handle        = auth.info.nickname
    u.twitter_location      = auth.info.location
    u.twitter_image         = auth.info.image
    u.twitter_description   = auth.info.description
    u.twitter_url           = auth.info.urls.Twitter

    u.save!
    
    return u
  end

  def tweet(tweet)
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
      config.access_token        = oauth_token
      config.access_token_secret = oauth_secret
    end
    
    client.update(tweet)
  end

end

require 'net/http'
require 'uri'

class Tweet
  include MongoMapper::Document
  # make all transactions to this model "safe" 
  # ie, NOT fire & forget
  safe
  
  key :id_str, String
  key :data, Hash
  key :goo_gl_success, Boolean
  key :goo_gl_long_url, String
  key :geohash_success, Boolean
  key :geohash_string, String
  key :geohash_box, Hash
  key :twitter_coords_success, Boolean
  key :lat, Float
  key :long, Float
  key :lat_long_method, String

  Tweet.ensure_index [[:id_str, 1]], :unique => true

  # Here is a sample/raw tweet (as json) (just for reference):
  #
  # {
  #   "created_at": "Wed Nov 26 03:32:06 +0000 2014",
  #   "id": 5.3744868513141e+17,
  #   "id_str": "537448685131407360",
  #   "text": "@BicycleRack oink oink",
  #   "source": "<a href=\"http:\/\/twitter.com\" rel=\"nofollow\">Twitter Web Client<\/a>",
  #   "truncated": false,
  #   "in_reply_to_status_id": null,
  #   "in_reply_to_status_id_str": null,
  #   "in_reply_to_user_id": 528911150,
  #   "in_reply_to_user_id_str": "528911150",
  #   "in_reply_to_screen_name": "BicycleRack",
  #   "user": {
  #     "id": 2904153008,
  #     "id_str": "2904153008",
  #     "name": "Test Ack Gack Frump",
  #     "screen_name": "AckGack",
  #     "location": "",
  #     "profile_location": null,
  #     "url": null,
  #     "description": null,
  #     "protected": false,
  #     "followers_count": 0,
  #     "friends_count": 3,
  #     "listed_count": 0,
  #     "created_at": "Wed Nov 19 04:53:58 +0000 2014",
  #     "favourites_count": 0,
  #     "utc_offset": null,
  #     "time_zone": null,
  #     "geo_enabled": false,
  #     "verified": false,
  #     "statuses_count": 4,
  #     "lang": "en",
  #     "contributors_enabled": false,
  #     "is_translator": false,
  #     "is_translation_enabled": false,
  #     "profile_background_color": "C0DEED",
  #     "profile_background_image_url": "http:\/\/abs.twimg.com\/images\/themes\/theme1\/bg.png",
  #     "profile_background_image_url_https": "https:\/\/abs.twimg.com\/images\/themes\/theme1\/bg.png",
  #     "profile_background_tile": false,
  #     "profile_image_url": "http:\/\/abs.twimg.com\/sticky\/default_profile_images\/default_profile_1_normal.png",
  #     "profile_image_url_https": "https:\/\/abs.twimg.com\/sticky\/default_profile_images\/default_profile_1_normal.png",
  #     "profile_link_color": "0084B4",
  #     "profile_sidebar_border_color": "C0DEED",
  #     "profile_sidebar_fill_color": "DDEEF6",
  #     "profile_text_color": "333333",
  #     "profile_use_background_image": true,
  #     "default_profile": true,
  #     "default_profile_image": true,
  #     "following": null,
  #     "follow_request_sent": null,
  #     "notifications": null
  #   },
  #   "geo": null,
  #   "coordinates": null,
  #   "place": null,
  #   "contributors": null,
  #   "retweet_count": 0,
  #   "favorite_count": 0,
  #   "entities": {
  #     "hashtags": [
  #
  #     ],
  #     "symbols": [
  #
  #     ],
  #     "user_mentions": [
  #       {
  #         "screen_name": "BicycleRack",
  #         "name": "Bicycle Rack",
  #         "id": 528911150,
  #         "id_str": "528911150",
  #         "indices": [
  #           0,
  #           12
  #         ]
  #       }
  #     ],
  #     "urls": [
  #
  #     ]
  #   },
  #   "favorited": false,
  #   "retweeted": false,
  #   "filter_level": "medium",
  #   "lang": "en",
  #   "timestamp_ms": "1416972726506"
  # }

  def self.maximum(column)
    self.first(:order => "#{column} desc").try(column)
  end

  def self.minimum(column)
    self.first(:order => "#{column} asc").try(column)
  end

  def has_goo_gl_link?
    data.try(:[], 'entities').try(:[], 'urls').try(:first).try(:[], 'expanded_url').try(:start_with?, 'http://goo.gl/maps/') || false
  end
  
  def goo_gl_link
    if has_goo_gl_link?
      data.try(:[], 'entities').try(:[], 'urls').try(:first).try(:[], 'expanded_url')
    else
      nil
    end
  end

  def goo_gl_long_link
    u = goo_gl_link
    return nil if u.blank?
    
    # http://stackoverflow.com/questions/5872210/get-redirect-of-a-url-in-ruby
    goo_gl = URI.parse(u)
    http = Net::HTTP.new goo_gl.host, goo_gl.port
    http.use_ssl = goo_gl.scheme == 'https'
    head = http.start do |r|
      r.head goo_gl.path
    end
  
    return head['location']
  end

  def set_lat_long_from_goo_gl_url
    self.goo_gl_long_url = goo_gl_long_link
    self.goo_gl_success = self.goo_gl_long_url.present?
    if goo_gl_success
      ll = goo_gl_long_url.scan(/q=([-\d\.]+),([-\d\.]+)/)
      if ll.present?
        self.lat = ll[0][0].to_f
        self.long = ll[0][1].to_f
        self.lat_long_method = :google_url
      end
    end

    return self
  end

  def extract_geohash_string
    
    urls = data.try(:[], 'entities').try(:[], 'urls')
    if urls.present?
      urls.each do |u|
        url = u['expanded_url']
        geohash = url.match(/bikerackmap.com\/g\/([0-9a-z]{9,12})/i).try(:captures).try(:[], 0)
        if geohash.present?
          return geohash
        end
      end
    end

    # If we didn't find a link with geohash, fall back to geohash:... or geo:hash:...
    data.try(:[], 'text').match(/geo:?hash:([0-9a-z]{9,12})/i).try(:captures).try(:[], 0) || nil
  end
  
  def set_lat_long_from_geohash
    # irb(main):001:0> GeoHash::decode('87z96u6mp')
    # [
    #     [0] [
    #         [0] 21.33768081665039,
    #         [1] -158.07888507843018
    #     ],
    #     [1] [
    #         [0] 21.33772373199463,
    #         [1] -158.07884216308594
    #     ]
    # ]

    s = extract_geohash_string
    if s.nil?
      self.geohash_success = false
    else
      box = GeoHash::decode(s)
      # [[north latitude, west longitude],[south latitude, east longitude]]
      self.geohash_box = {
        :north_lat => box[0][0],
        :west_long => box[0][1],
        :south_lat => box[1][0],
        :east_long => box[1][1]
      }
      self.geohash_string = s
      self.lat = (geohash_box[:north_lat] + geohash_box[:south_lat]) / 2.0
      self.long = (geohash_box[:west_long] + geohash_box[:east_long]) / 2.0
      self.geohash_success = true
      self.lat_long_method = :geohash_string
    end
    
    return self
  end
  
  def set_lat_long_by_twitter_coords
    ll = data.try(:[], 'coordinates').try(:[], 'coordinates')
    if ll.present?
      self.lat = ll[1]
      self.long = ll[0]
      self.lat_long_method = :twitter_coords
      self.twitter_coords_success = true
    else
      self.twitter_coords_success = false
    end

    return self
  end

  def recompute_lat_long
    # first try geohash:.....
    set_lat_long_from_geohash
    # second try google map url/link
    (lat.blank? || long.blank?) && set_lat_long_from_goo_gl_url
    # last, use the geo data from twitter
    (lat.blank? || long.blank?) && set_lat_long_by_twitter_coords
    
    if lat.blank?
      self.lat_long_method = :fail
    end
    
    return self
  end
  
  def Tweet.force_update_all_lat_long
    Tweet.all.each do |t|
      t.recompute_lat_long
      t.changed? && t.save!
    end
    true
  end
  
  def Tweet.update_missing_lat_longs
    Tweet.where(:lat.exists => false).where(:lat_long_method.exists => false).each do |t|
      t.recompute_lat_long
      t.changed? && t.save!
    end
    true
  end
  
  def Tweet.insert_tweet(x, do_recompute_lat_long=true)
    x = Oj.load(x.to_json)

    # ignore retweets (duplicates)
    return nil if x['retweeted']
    # ignore tweets that do not mention us by name
    return nil if x['text'] !~ /@bicyclerack/i
    # ignore our own tweets
    return nil if x['user']['screen_name'] =~ /bicyclerack/i

    id_str = x['id_str']
    t = Tweet.first_or_new(:id_str => id_str)
    t.data = x

    if do_recompute_lat_long
      t.recompute_lat_long
    end

    t.save!
  end
end

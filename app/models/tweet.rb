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
  key :geohash_box, Hash
  key :twitter_coords_success, Boolean
  key :lat, Float
  key :long, Float
  key :lat_long_method, String

  Tweet.ensure_index [[:id_str, 1]], :unique => true

  def Tweet.insert_tweet(x)
    x = Oj.load(x.to_json)
    id_str = x['id_str']
    t = Tweet.first_or_new(:id_str => id_str)
    t.data = x
    t.save
  end
  
  def Tweet.reload_all_mentions
    # first tweet @bicyclerack: https://twitter.com/phlatphrog/status/181524058561716225
    Twitter.mentions_timeline(:since_id => "181524058561716224", :count => 200).each do |t|
      Tweet.insert_tweet(t)
    end
  end
  
  def Tweet.insert_new_tweet(x)
    x = Oj.load(x.to_json)
    id_str = x['id_str']
    t = Tweet.where(:id_str => id_str).first
    if t.present?
      t
    else
      Tweet.create(:id_str => id_str, :data => x)
    end
  end
  
  def Tweet.load_new_mentions
    Twitter.mentions_timeline.each do |t|
      Tweet.insert_new_tweet(t)
    end
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

  def update_goo_gl_long_url
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
    self.save
  end

  def geohash_string
    data.try(:[], 'text').match(/geohash:([0-9a-z]{9,12})/i).try(:captures).try(:[], 0) || nil
  end
  
  def compute_geohash_coords
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

    s = geohash_string
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
      self.lat = (geohash_box[:north_lat] + geohash_box[:south_lat]) / 2.0
      self.long = (geohash_box[:west_long] + geohash_box[:east_long]) / 2.0
      self.geohash_success = true
      self.lat_long_method = :geohash_string
    end
    
    return self
  end
  
  def update_geohash_coords
    self.compute_geohash_coords
    self.save
  end

  def update_by_twitter_coords
    ll = data.try(:[], 'coordinates').try(:[], 'coordinates')
    if ll.present?
      self.lat = ll[1]
      self.long = ll[0]
      self.lat_long_method = :twitter_coords
      self.twitter_coords_success = true
    else
      self.twitter_coords_success = false
    end

    self.save
  end

  def recompute_lat_long
    # first try geohash:.....
    update_geohash_coords
    # second try google map url/link
    lat.present? || update_goo_gl_long_url
    # last, use the geo data from twitter
    lat.present? || update_by_twitter_coords
  end
  
  def Tweet.force_update_all_lat_long
    Tweet.all.each do |t|
      t.recompute_lat_long
    end
    true
  end
  
  def Tweet.update_missing_lat_longs
    Tweet.where(:lat.exists => false).each do |t|
      t.recompute_lat_long
    end
    true
  end
end

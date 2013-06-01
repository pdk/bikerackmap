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
  key :lat, Float
  key :long, Float

  Tweet.ensure_index [[:id_str, 1]], :unique => true

  def Tweet.insert_tweet(x)
    x = Oj.load(x.to_json)
    id_str = x['id_str']
    t = Tweet.first_or_new(:id_str => id_str)
    t.data = x
    t.save
  end
  
  def Tweet.reload_all_mentions
    Twitter.mentions_timeline.each do |t|
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
      end
    end
    self.save
  end

  def Tweet.update_all_goo_gls
    Tweet.where(:goo_gl_success.exists => false).each do |t|
      t.update_goo_gl_long_url
    end
  end

  def Tweet.update_missing_lat_longs
    Tweet.where(:lat.exists => false).each do |t|
      ll = t.data.try(:[], 'coordinates').try(:[], 'coordinates')
      if ll.present?
        t.lat = ll[0]
        t.long = ll[1]
        t.save
      end
    end
  end
end

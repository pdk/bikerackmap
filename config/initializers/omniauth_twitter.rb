Rails.application.config.middleware.use OmniAuth::Builder do

  provider :developer unless Rails.env.production?
  provider :twitter, ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET'],
    {
      :secure_image_url => 'true',
      :image_size => 'bigger',
      :authorize_params => {
        :force_login => 'false'
      }
    }
end

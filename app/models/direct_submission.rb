class DirectSubmission
  include MongoMapper::Document

  key :lat, Float
  key :long, Float
  key :text, String
  key :photo_url, String

end

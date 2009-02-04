class RouteRule < ActiveRecord::Base
  validates_presence_of :did
  validates_presence_of :url
  validates_length_of :did, :is=>10
  validate :is_valid_uri, :if=>!:url_present?
  
  def did=(user_did)
    write_attribute(:did, user_did.gsub(/[^0-9]/, ''))
  end
  
  private
  
  def url_present?
    return !self.url.blank?
  end

  def is_valid_uri
    begin
      if URI.parse(self.url).kind_of?(URI::HTTP)
        return true
      end
    rescue
    end
    errors.add_to_base("Must provide a valid URL.")
  end
end

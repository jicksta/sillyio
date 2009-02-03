class RouteRule < ActiveRecord::Base
  validates_presence_of :did
  validates_presence_of :url
end

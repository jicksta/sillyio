class CallerId < ActiveRecord::Base
  validates_presence_of :did
  validates_presence_of :description
  validates_length_of :did, :is=>10
  
  def did=(user_did)
    write_attribute(:did, user_did.gsub(/[^0-9]/, ''))
    #only overwrite the description if it is blank or is a default (phone number formatted string)
    if self.description.blank? || self.description.match(/^\([0-9]{3}\) [0-9]{3}\-[0-9]{4}$/) != nil
      write_attribute(:description, format_did_for_description(self.did))
    end
  end
  
  private
  def format_did_for_description(clean_did)
    if clean_did.size == 10
      return "(#{clean_did[0..2]}) #{clean_did[3..5]}-#{clean_did[6..9]}"
    else
      return nil
    end
  end
end

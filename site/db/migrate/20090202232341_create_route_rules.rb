class CreateRouteRules < ActiveRecord::Migration
  def self.up
    create_table :route_rules do |t|
      t.string :did, :limit=>10
      t.string :url
      t.timestamps
    end
  end

  def self.down
    drop_table :incomings
  end
end

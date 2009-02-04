class CreateCallerIds < ActiveRecord::Migration
  def self.up
    create_table :caller_ids do |t|
      t.string :did, :limit=>10
      t.string :description
      t.timestamps
    end
  end

  def self.down
    drop_table :caller_ids
  end
end

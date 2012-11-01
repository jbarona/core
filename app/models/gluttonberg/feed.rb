module Gluttonberg
  class Feed < ActiveRecord::Base
    belongs_to :user
    belongs_to :feedable, :polymorphic => true
    self.table_name = "gb_feeds"
    attr_accessible :user, :feedable_type, :feedable_id, :title, :action_type

    def self.log(user,object,title,action_type)
      self.create(:user => user , :feedable_type => object.class.to_s,  :feedable_id => object.id, :title => title , :action_type => action_type)
    end


  end
end
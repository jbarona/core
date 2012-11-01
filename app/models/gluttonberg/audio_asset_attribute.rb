module Gluttonberg
  class AudioAssetAttribute < ActiveRecord::Base
      belongs_to :asset
      self.table_name = "gb_audio_asset_attributes"
      attr_accessible :asset_id , :length , :title , :artist , :album, :tracknum , :genre

  end #class
end   #module
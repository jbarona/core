# encoding: utf-8
module Gluttonberg
  module Content
    # This module can be mixed into a class to provide slug management methods
    module SlugManagement
      extend ActiveSupport::Concern
      
      included do
        before_validation :slug_management
        class << self;  attr_accessor :slug_source_field_name end
        attr_accessor :current_slug
      end
      
      module ClassMethods
        def self.check_for_duplication(slug, object, potential_duplicates)
          unless potential_duplicates.blank?
            if potential_duplicates.length > 1 || (potential_duplicates.length == 1 && potential_duplicates.first.id != object.id )
              slug = "#{slug}-#{potential_duplicates.length+1}"
            end
          end
          slug
        end
      end


      def get_slug_source
        if self.class.slug_source_field_name.blank?
          if self.respond_to?(:name)
            self.class.slug_source_field_name= :name
          elsif self.respond_to?(:title)
            self.class.slug_source_field_name= :title
          else
            self.class.slug_source_field_name= :id
          end
        end
        self.class.slug_source_field_name
      end

      def slug=(new_slug)
        current_slug = self.slug
        new_slug = new_slug.sluglize unless new_slug.blank?
        new_slug = unique_slug(new_slug)
        write_attribute(:slug, new_slug)
        if self.respond_to?(:previous_slug) && self.slug_changed? && self.slug != current_slug
          write_attribute(:previous_slug, current_slug)
        end
        new_slug
      end

      protected
      # Checks If slug is blank then tries to set slug using following logic
      # if slug_field_name is set then use its value and make it slug
      # otherwise checks for name column
      # otherwise checks for title column
      # else get id as slug
        def slug_management
          if self.slug.blank?
            if self.class.slug_source_field_name.blank?
              self.get_slug_source
            end
            self.slug= self.send(self.class.slug_source_field_name)
          end #slug.blank
          self.fix_duplicated_slug
        end

        def fix_duplicated_slug
          # check duplication: add id at the end if its duplicated
          already_exist = self.class.where(:slug => self.slug).all
          unless already_exist.blank?
            if already_exist.length > 1 || (already_exist.length == 1 && already_exist.first.id != self.id )
              self.slug= "#{self.slug}-#{already_exist.length+1}"
            end
          end
        end

        def unique_slug(slug)
          # check duplication: add id at the end if its duplicated
          potential_duplicates = self.class.where(:slug => slug).all
          Content::SlugManagement::ClassMethods.check_for_duplication(slug, self, potential_duplicates)
        end


    end
  end
end

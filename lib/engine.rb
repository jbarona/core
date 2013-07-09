require 'gluttonberg'
require 'rails'

module Gluttonberg
  class Engine < Rails::Engine

    # Config defaults
    def init_basic_settings
      config.mount_at = '/'
      config.app_name = 'Gluttonberg'
      config.max_image_size = "1600x1200>"
      config.thumbnails = {}
      config.enable_gallery = false
      config.enable_members = false
      config.encoding = "utf-8"
      config.host_name = "localhost:3000"
    end

    def init_advance_settings
      config.asset_storage = :filesystem
      #engines which depends on gluttonberg-core can
      #use this to provide additional processor for assets
      #in first stage I am going to use it with Tv
      config.asset_processors = []
      config.asset_mixins = []
      config.custom_css_for_cms = false
      config.custom_js_for_cms = false
      # User model always concat following three roles
      # ["super_admin" , "admin" , "contributor"]
      config.user_roles = []
      config.cms_based_public_css = false
      config.flagged_content = false
      config.search_models = {
        "Gluttonberg::Page" => [:name],
        "Gluttonberg::Blog" => [:name , :description],
        "Gluttonberg::ArticleLocalization" => [:title , :body],
        "Gluttonberg::PlainTextContentLocalization" => [:text] ,
        "Gluttonberg::HtmlContentLocalization" => [:text]
      }
      config.honeypot_field_name = "our_newly_weekly_series"
      config.localize = false
      config.member_csv_metadata = { 
        :first_name => "FIRST NAME", 
        :last_name => "LAST NAME",  
        :email => "EMAIL", 
        :groups => "GROUPS", 
        :bio => "BIO"
      }
      config.member_mixins = []
      config.password_pattern = /^(?=.*\d)(?=.*[a-zA-Z])(?!.*[^\w\S\s]).{6,}$/
      config.password_validation_message = "must be a minimum of 6 characters in length, contain at least 1 letter and at least 1 number"
      config.multisite = false
    end

    def init_internal_settings
      config.identify_locale = :prefix
      config.active_record.observers = ['gluttonberg/page_observer', 
        'gluttonberg/page_localization_observer' , 
        'gluttonberg/locale_observer' 
      ]
    end
    
    

    def init_asset_precompile
      
    end

    
    init_basic_settings
    init_advance_settings
    init_internal_settings
    init_asset_precompile
    if Rails.version > "3.1"
      initializer "Gluttonberg precompile hook", :group => :all do |app|
        app.config.assets.precompile += ["*.js", "*.css"]
      end
    end
    

    # Load rake tasks
    rake_tasks do
      load File.join(File.dirname(__FILE__), 'rails/railties/tasks.rake')
      load File.join(File.dirname(__FILE__), 'gluttonberg/tasks/asset.rake')
      load File.join(File.dirname(__FILE__), 'gluttonberg/tasks/gluttonberg.rake')
    end

    # Check the gem config
    initializer "check config" do |app|

      # make sure mount_at ends with trailing slash
      config.mount_at += '/'  unless config.mount_at.last == '/'
    end

    initializer "static assets" do |app|
      app.middleware.use ::ActionDispatch::Static, "#{root}/public"
    end

    initializer "middleware" do |app|
      app.middleware.use Gluttonberg::Middleware::Locales
      app.middleware.use Gluttonberg::Middleware::Rewriter
      app.middleware.use Gluttonberg::Middleware::Honeypot , config.honeypot_field_name
    end


    initializer "setup gluttonberg components" do |app|
      Gluttonberg::Content::Versioning.setup
      Gluttonberg::Content::ImportExportCSV.setup
      Gluttonberg::Content::CleanHtml.setup
      Gluttonberg::PageDescription.setup

      # register content class here.
      # It is required for lazyloading environments.
      Gluttonberg::Content::Block.register(Gluttonberg::PlainTextContent)
      Gluttonberg::Content::Block.register(Gluttonberg::HtmlContent)
      Gluttonberg::Content::Block.register(Gluttonberg::ImageContent)

      Gluttonberg::Content.setup

      Gluttonberg::CanFlag.setup
      Time::DATE_FORMATS[:default] = "%d/%m/%Y %I:%M %p"
      Components.init_main_nav
    end

    initializer "setup acts-as-taggable-on" do |app|
      require "acts-as-taggable-on"
      if ::ActsAsTaggableOn::Tag.attribute_names.include?("slug") == true
        ::ActsAsTaggableOn::Tag.send(:include , Gluttonberg::Content::SlugManagement)
      end
    end

    initializer "setup active_link_to" do |app|
      require 'active_link_to'
    end

    initializer "setup delayed job" do |app|
      Delayed::Job.attr_accessible :priority, :payload_object, :handler, :run_at, :failed_at
    end
  end
end

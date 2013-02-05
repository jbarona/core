module Gluttonberg
    # Helpers specific to the administration interface. The majority are
    # related to forms, but there are other short cuts for things like navigation.
    module Admin
      # A form helper which automatically injects the form builder which
      # automatically wraps the fields in divs.
      def admin_form(obj, opts = {}, &blk)
        opts.merge!(:builder => Gluttonberg::Helpers::FormBuilder)
        form_for(obj, opts, &blk)
      end

      # Returns a form for selecting the localized version of a record you want
      # to edit.
      # TODO DO we need that
      def localization_picker(url)
        # Collect the locale/dialect pairs
        locales = ::Gluttonberg::Locale.all(:fields => [:id, :name])
        localizations = []
        locales.each do |locale|
            localizations << ["#{locale.id}", "#{locale.name}"]
        end
        # Output the form for picking the locale
        form(:action => url, :method => :get, :id => "select-localization") do
          output = ""
          output << select(:name => :localization, :collection => localizations, :label => "Select localization", :selected => params[:localization])
          output << button("Edit", :class => "buttonGrey")
        end
      end

      # Returns a form for selecting the localized version of a record you want
      # to edit.
      def page_localization_picker(page_localizations)

      end


      # Returns a text field with the name, id and values for the localized
      # version of the specified attribute.
      def localized_text_field(name, opts = {})
        final_opts = localized_field_opts(name)
        text_field(final_opts.merge!(opts))
      end

      # Returns a text area with the name, id and values for the localized
      # version of the specified attribute.
      def localized_text_area(name, opts = {})
        text_area(get_localized_value(name), localized_field_opts(name, false).merge!(opts))
      end

      # Returns a hash of common options to be used in the localized versions
      # of fields.
      def localized_field_opts(name, set_value = true)
        prefix = current_form_context.instance_variable_get(:@name)
        opts = {
          :name   => "#{prefix}[localized_attributes][#{name}]",
          :id     => "#{prefix}_localized_#{name}"
        }
        opts[:value] = get_localized_value(name) if set_value
        opts
      end

      # Returns a hidden field which stores the localization param in the form.
      def localization_field
        hidden_field(:name => "localization", :value => params[:localization])
      end

      def get_localized_value(name)
        @localized_model ||= current_form_context.instance_variable_get(:@obj)
        @localized_model.current_localization.send(name)
      end

      # Checks to see if there is a matching help page for this particular
      # controller/action. If there is it renders a link to the help
      # controller.
      def contextual_help

        if Help.help_available?(:controller => params[:controller], :page => params[:action])
          content_tag(
            :p,
            link_to("Help", admin_help_path(:module_and_controller => params[:controller], :page => params[:action]), :class => "button"),
            :id => "contextualHelp"
          )
        end
      end

      # TODO Do we need these?
      # Generates a styled tab bar
      def tab_bar(&blk)
        content_tag(:ul, {:id => "tabBar"}, &blk)
      end

      # For adding a tab to the tab bar. It will automatically mark the current
      # tab by examining the request path.
      def tab(label, url)
        if request.env["REQUEST_PATH"] && request.env["REQUEST_PATH"].match(%r{^#{url}})
          content_tag(:li, link_to(label, url), :class => "current")
        else
          content_tag(:li, link_to(label, url))
        end
      end

      # If it's passed a label this method will return a fieldset, otherwise it
      # will just return the contents wrapped in a block.
      def block(label = nil, opts = {}, &blk)
        if label
          field_set_tag(label) do
            content_tag(:fieldset, opts, &blk)
          end
        else
          content_tag(:fieldset, opts, &blk)
        end
      end

      # Controls for standard forms. Writes out a save button and a cancel link
      def form_controls(return_url , opts={})
        content = "#{submit_tag("Save" , :id => opts[:submit_id], :class => "btn btn-success").html_safe} #{link_to("Cancel".html_safe, return_url, :class => "btn")}"
        content_tag(:p, content.html_safe, :class => "controls")
      end

      # Controls for publishable forms. Writes out a draft ,  publish/unpublish button and a cancel link
      def publishable_form_controls(return_url , object_name , is_published )
        content = hidden_field(:published , :value => false)
        content += "#{link_to("<strong>Cancel</strong>", return_url)}"
        content += " or #{submit_tag("draft")}"
        content += " or #{submit_tag("publish" , :onclick => "publish('#{object_name}_published')" )}"
        content_tag(:p, content, :class => "controls")
      end

      # Writes out a nicely styled subnav with an entry for each of the
      # specified links.
      def sub_nav(&blk)
        content_tag(:ul, :id => "subnav", :class => "nav nav-pills", &blk)
      end

      # Writes out a link styled like a button. To be used in the sub nav only
      def nav_link(*args)
        class_names = "button"
        class_names = "#{class_names} #{args[2][:class]}" if args.length >= 3
        content_tag(:li, active_link_to(args[0] , args[1] , :title => args[0]), :class => class_names)
      end

      # Writes out the back control for the sub nav.
      def back_link(name, url)
        content_tag(:li, link_to(name, url , :title => name), :id => "backLink")
      end

      # Takes text and url and checks to see if the path specified matches the
      # current url. This is so we can add a highlight.
      def main_nav_entry(text, mod, url = nil, opts = {})
        if url
          li_opts = {:id => "#{mod}Nav"}
          if( ( request.env["REQUEST_PATH"] && (request.env["REQUEST_PATH"].match(%r{/#{mod}}) || request.env["REQUEST_PATH"] == url) )  || (request.env["REQUEST_PATH"] && request.env["REQUEST_PATH"].include?("content") && request.env["REQUEST_PATH"] == url ) )
            li_opts[:class] = "current"
          end
          content_tag("li", link_to(text, url, opts), li_opts)
        end
      end

      def gb_error_messages_for(model_object)
        if model_object.errors.any?
            lis = ""
            model_object.errors.full_messages.each do |msg|
              lis << content_tag(:li , msg)
            end
          ul = content_tag(:ul , lis.html_safe).html_safe
          heading = content_tag(:h4 , "Sorry there was an error" , :class => "alert-heading" )
          content_tag(:div , (heading.html_safe + ul.html_safe) , :class => "model-error alert alert-block alert-error")
        end
      end

      def website_title
        title = Gluttonberg::Setting.get_setting("title")
        (title.blank?)? "Gluttonberg" : title.html_safe
      end

      # Writes out a row for each page and then for each page's children,
      # iterating down through the heirarchy.
      def page_table_rows(pages, output = "", inset = 0 , row = 0)
        pages.each do |page|
          row += 1
          output << render( :partial => "gluttonberg/admin/content/pages/row", :locals => { :page => page, :inset => inset , :row => row })
          page_table_rows(page.children, output, inset + 1 , row)
        end
        output.html_safe
      end


      def publisable_dropdown(form ,object)
        val = object.state
        val = "ready" if val.blank? || val == "not_ready"
        @@workflow_states = [  [ 'Draft' , 'ready' ] , ['Published' , "published" ] , [ "Archived" , 'archived' ]  ]
        form.select( :state, options_for_select(@@workflow_states , val)   )
      end

      # shows publish message if object's currect version is published
      def publish_message(object , versions)
        content = msg = ""

        if versions.length > 1
          msg = content_tag(:a,  "Click here to see other versions" , :onclick => "$('#select-version').toggle();" , :href => "javascript:;"  , :title => "Click here to see other versions").html_safe
          msg = content_tag(:span , msg , :class => "view-versions").html_safe
        end

        content = content_tag(:div , "Updated on #{object.updated_at.to_s(:long)}    #{msg}".html_safe , :class => "unpublish_message") unless object.updated_at.blank?
        content.html_safe
      end

      def version_listing(versions , selected_version_num)
        unless versions.blank?
          output = "<div class='historycontrols'>"
          selected = versions.last.version
          selected_version = versions.last
          collection = []
          versions.each do |version|
            link = version.version
            snippet = "Version #{version.version} - #{version.updated_at.to_s(:long)}  " unless version.updated_at.blank?
            if version.version.to_i == selected_version_num.to_i
              selected = link
              selected_version = version
            end
            collection << [snippet , link]
          end

          # Output the form for picking the version
          versions_html = "<ul class='dropdown-menu'>"
          collection.each do |c|
            versions_html << content_tag(:li , link_to(c[0] , "?version=#{c[1]}") , :class => "#{c[1].to_s == selected.to_s ? 'active' : '' }" )
          end
          versions_html << "</ul>"

          current_version = '<a class="btn dropdown-toggle" data-toggle="dropdown" href="#">'
          current_version += "Editing Version #{selected_version.version} "
          current_version += '<span class="caret"></span>'
          current_version += '</a>'

          combined_versions = current_version
          combined_versions += versions_html

          output << content_tag(:div , combined_versions.html_safe, :class => "btn-group" )

          output += "</div>"
          output += "<div class='clear'></div>"
          output += "<br />"
          output += "<br />"
          output.html_safe
        end
      end

      def custom_stylesheet_link_tag
        if Rails.configuration.custom_css_for_cms == true
          stylesheet_link_tag "custom"
        end
      end

      def custom_javascript_include_tag
        if Rails.configuration.custom_js_for_cms == true
          javascript_include_tag "custom"
        end
      end

      def wysiwyg_js_css_link_tag
        if Gluttonberg::Setting.get_setting("enable_WYSIWYG") == "Yes"
          javascript_include_tag("/assets/tiny_mce/jquery.tinymce.js")
        end
      end

      def tags_string(tag_type)
        @themes = ActsAsTaggableOn::Tag.find_by_sql(%{select DISTINCT tags.id , tags.name
          from tags inner join taggings on tags.id = taggings.tag_id
          where context = '#{tag_type}'
        })
        output = ""
        @themes.each do |theme|
          output << "," unless output.blank?
          output << theme.name
        end
        output
      end


      def honeypot_field_tag
        html = label_tag(Rails.configuration.honeypot_field_name , Rails.configuration.honeypot_field_name.humanize )
        html << text_field_tag( Rails.configuration.honeypot_field_name )
        content_tag :div , html , :class => Rails.configuration.honeypot_field_name , :style => "display:none"
      end

      def date_format(date_time)
        if date_time < 1.week.ago
          date_time.strftime("%d/%m/%Y")
        else
          time_ago_in_words(date_time)
        end
      end

      def backend_logo(default_logo_image_path , html_opts={}, thumbnail_type = :backend_logo)
        backend_logo = Gluttonberg::Setting.get_setting("backend_logo")
        asset = Asset.find(:first , :conditions => { :id => backend_logo } )
        unless asset.blank?
          path = thumbnail_type.blank? ? asset.url : asset.url_for(thumbnail_type)
          content_tag(:img , "" , html_opts.merge( :alt => asset.name , :src => path ) )
        else
          image_tag(default_logo_image_path)
        end
      end

      def render_flash_messages
          html = ""
          ["notice", "warning", "error"].each do |type|
              unless flash[type.intern].nil?
                  html << content_tag("div", flash[type.intern].to_s.html_safe,
                      :id => "alert alert-#{type}", :class => "flash").html_safe
              end
          end

          content_tag("div", html.html_safe, :id => "flash").html_safe
      end


      # Creates an editable span for the given property of the given object.
      #
      # === Options
      #
      # [:method]
      #   Specify the HTTP method to use: <tt>'PUT'</tt> or <tt>'POST'</tt>.
      # [:name]
      #   The <tt>name</tt> attribute to be used when the form is posted.
      # [:update_url]
      #   The URL to submit the form to.  Defaults to <tt>url_for(object)</tt>.
      def gb_editable_field(object, property, options={})

        name = "#{object.class.to_s.underscore}[#{property}]"
        value = object.send property
        update_url = options.delete(:update_url) || url_for(object)
        args = {:method => 'PUT', :name => name}.merge(options)
        %{
          <span class="editable" data-id="#{object.id}" data-name="#{name}">#{value}</span>
          <script type="text/javascript">
            (function( $ ){
              $(function(){
                var args = {data: function(value, settings) {
                  // Unescape HTML
                  var retval = value
                    .replace(/&amp;/gi, '&')
                    .replace(/&gt;/gi, '>')
                    .replace(/&lt;/gi, '<')
                    .replace(/&quot;/gi, "\\\"");
                  return retval;
                },
                   type      : 'text',
                   height : '20px',
                   cancel    : 'Cancel',
                   submit    : 'OK',
                   indicator : '#{image_tag('/assets/gb_spinner.gif')}'
                };
                $.extend(args, #{args.to_json});
                $(".editable[data-id='#{object.id}'][data-name='#{name}']").editable("#{update_url}", args);
              });
            })( jQuery );
          </script>
        }.html_safe
      end

      def sortable_column(column, title = nil)
        title ||= column.titleize
        css_class = column == sort_column ? "current #{sort_direction}" : nil
        direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
        new_params = params.merge(:sort => column, :direction => direction)
        link_to title, new_params, {:class => css_class}
      end

      def slug_donotmodify_val
        action_name == "edit"  || action_name == "update"
      end

      def current_domain
        domain = "#{request.protocol}#{request.host_with_port}/"
        domain.strip
      end

    end # Admin
end # Gluttonberg


module ActionView
  module Helpers
    class FormBuilder
        include ActionView::Helpers


        def publisable_dropdown
          object = self.object
          val = object.state
          if val == "not_ready"
            val = "ready"
          else
            val = "published"
          end
          @@workflow_states = [  ['Published' , "published" ] ,[ 'Draft' , 'ready' ] , [ "Archived" , 'archived' ]  ]
          object.published_at = Time.zone.now if object.published_at.blank?
          html = "<fieldset id='publish_meta'><div class='publishing_block' > "
          html += select( :state, options_for_select(@@workflow_states , val), {} , :class => "publishing_state" )
          # html += content_tag(:p , self.datetime_select("published_at" , {:prompt => {:day => 'Day', :month => 'Month', :year => 'Year'} , :order => [:day , :month , :year] }, :class => "span2") , :class => "published_at" )
          #
          html += datetime_field("published_at")
          html += "</div></fieldset>"

          html.html_safe
        end

        def datetime_field(field_name,date_field_html_opts = {},time_field_html_opts = {})
          date_field_html_opts["data-datepicker"] = "bsdatepicker"
          unique_field_name = "#{field_name}_#{Gluttonberg::Member.generateRandomString}"
          date_field_html_opts[:onblur] = "checkDateFormat(this,'.#{unique_field_name}_error');combine_datetime('#{unique_field_name}');"
          if date_field_html_opts[:class].blank?
            date_field_html_opts[:class] = "small span2 datefield"

          else
            date_field_html_opts[:class] += " small span2 datefield"
          end

          if time_field_html_opts[:class].blank?
            time_field_html_opts[:class] = " small span2 timefield"
          else
            time_field_html_opts[:class] += " small span2 timefield"
          end
          time_field_html_opts[:onblur] = "checkTimeFormat(this,'.#{unique_field_name}_error');combine_datetime('#{unique_field_name}')"

          html = ""
          date = ""
          time = ""
          unless self.object.send(field_name).blank?
            date = self.object.send(field_name).strftime("%d/%m/%Y")
            time = self.object.send(field_name).strftime("%I:%M %p")
          end
          html += text_field_tag("#{unique_field_name}_date" , date , date_field_html_opts )
          # html += "<span class='date'>DD/MM/YYYY</span>"
          html += " "
          html += text_field_tag("#{unique_field_name}_time" , time , time_field_html_opts )
          # html += "<span class='date time'>HH:MM AM/PM</span>"
          html += self.hidden_field("#{field_name}" ,  :class => "#{unique_field_name}")
          html += "<span class='help-block'><span class='span2'>DD/MM/YYYY</span> <span class='span2'>HH:MM AM/PM</span></span>"
          html += "<label class='error #{unique_field_name}_error'></label>"
          html += "<div class='clear'></div>"
          html += "<script type='text/javascript'>$(document).ready(function() { combine_datetime('#{unique_field_name}'); }); </script>"
          html.html_safe
        end

    end
  end
end

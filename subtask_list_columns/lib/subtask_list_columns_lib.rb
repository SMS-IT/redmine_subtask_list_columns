require_dependency 'issues_helper'
require 'date'

module SubtaskListColumnsLib
    
    def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable

            alias_method_chain :render_descendants_tree, :listed
      end
    end

    module InstanceMethods

      def render_descendants_tree_with_listed(issue)
       
        fields_list = get_fields_for_project(issue.project_id, issue.project.all_issue_custom_fields)
                
        field_values = ''
        field_headers = ''
        map = []
        s = '<form><table class="list issues">'
         
        issue_list(issue.descendants.visible.sort_by(&:lft)) do |child|
            custom_fields = child.available_custom_fields
            custom_fields.each do |field|
              if field.listed? and map.find_index(field.name).nil?
                field_headers << content_tag('th', field.name)
                map << field.name
              end
            end
          end
        
        
        if(fields_list.count == 0) 
          #if the project column is not set, show: subject, status, assigned_to and done_ratio
         
          s << content_tag('tr',
          content_tag('th', l(:field_subject)) +
          content_tag('th', l(:field_status)) +
          content_tag('th', l(:field_assigned_to)) +   
          field_headers.html_safe +       
          content_tag('th', l(:field_done_ratio)))

          issue_list(issue.descendants.visible.sort_by(&:lft)) do |child, level|
            custom_fields = child.available_custom_fields
            css = "issue issue-#{child.id} hascontextmenu"
            css << " idnt idnt-#{level}" if level > 0
            field_content = 
               content_tag('td', check_box_tag("ids[]", child.id, false, :id => nil), :class => 'checkbox') +
               content_tag('td', link_to_issue(child, :truncate => 160), :class => 'subject') +
               content_tag('td align="center"', h(child.status)) +
               content_tag('td align="center"', link_to_user(child.assigned_to))

            map.each do |field|
              found = false
              child.custom_field_values.each do |cv|
                if (field == cv.custom_field.name)
                  found = true
                  field_content << content_tag('td align="right"', cv.value)
                end
              end
              field_content << content_tag('td bgcolor="#dddddd" class="no-field-owner"', '') unless found
            end
      
            field_content << content_tag('td', progress_bar(child.done_ratio, :width => '80px'))
            field_values << content_tag('tr', field_content, :class => css).html_safe
          end
          
        else 
          # show columns from table
          
          # set header - columns names
          s << content_tag('th style="text-align:left"', l(:field_subject))       
          fields_list.each do |field|
            if(field['ident'] == 'tracker' || field['ident'] == 'subject')
              next
            end  
            custom_field_id = field['ident'].to_i
            # custom fields idents is integer type, default is string
            if(custom_field_id == 0)                            
              current_field = Constants::DEFAULT_FIELDS.find {|f| f['ident'] == field['ident']}            
            else
              current_field = CustomField.find_by id: custom_field_id                   
            end
            
            field_name = current_field['name'].nil? ? 'No name' : current_field['name']
              s << content_tag('th style="text-align:left"', field_name)                        
          end
          
          # set data
          issue_list(issue.descendants.visible.sort_by(&:lft)) do |child, level|
              custom_fields = child.available_custom_fields
              css = "issue issue-#{child.id} hascontextmenu"
              css << " idnt idnt-#{level}" if level > 0
              
              field_content = 
                content_tag('td', check_box_tag("ids[]", child.id, false, :id => nil), :class => 'checkbox') +
                get_first_column_in_table(child, !fields_list.detect{|f| f['ident'] == 'tracker'}.nil?, !fields_list.detect{|f| f['ident'] == 'subject'}.nil?)
           
              fields_list.each do |field|
                 if(field['ident'] == 'tracker' || field['ident'] == 'subject')
                  next
                end               
                
                found = false
                
                # first looking for the default
                if (Constants::DEFAULT_FIELDS.detect {|f| f['ident'] == field['ident']}.nil? == false)
                  
                  found = true
                  
                  case field['ident']
                  when 'project'
                    field_content << get_td(link_to_project(child.project))
                  when 'description'
                    field_content << get_td(child.description.truncate(100)) 
                  when 'due_date'
                    field_content << get_td(format_date(child.due_date))
                  when 'category'
                    field_content << get_td(child.category)
                  when 'status'
                    field_content << get_td(h(child.status))                    
                  when 'assigned_to'
                    field_content << get_td(link_to_user(child.assigned_to))
                  when 'priority'
                    field_content << get_td(child.priority)
                  when 'fixed_version'
                    field_content << get_td(link_to_version(child.fixed_version))    
                  when 'author'
                    field_content << get_td(link_to_user(child.author)) 
                  when 'created_on'
                    field_content << get_td(format_time(child.created_on))
                  when 'updated_on'
                    field_content << get_td(format_time(child.updated_on))
                  when 'start_date'
                    field_content << get_td(format_date(child.start_date))
                  when 'done_ratio'
                    field_content << get_td(progress_bar(child.done_ratio, :width => '70px'))
                  when 'estimated_hours'
                    field_content << get_td(child.estimated_hours)  
                  when 'parent'
                    field_content << get_td(link_to_issue(child.parent, :tracker=> false, :subject => false))  
                  when 'closed_on'
                    field_content << get_td(format_time(child.closed_on))
                  when 'is_private'
                    field_content << get_td(child.is_private ? l(:general_text_yes) : l(:general_text_no))                  
                  when 'remaining_time'
                    field_content << get_td(child.remaining_time)
                  else
                    
                  end
                    
                else
                  # then custom
                  child.custom_field_values.each do |cv|
                    custom_field_id = field['ident'].to_i
                    if (custom_field_id == cv.custom_field.id)
                      found = true
                      if (cv.custom_field.field_format == "bool")
                        value = cv.value == "1" ? l(:general_text_yes) : l(:general_text_no)
                      else
                        value = cv.value                      
                      end
                      field_content << get_td(value)
                    end                               
                  end
                end
                
                field_content << content_tag('td bgcolor="#dddddd" class="no-field-owner"', '') unless found
                
              end
            field_values << content_tag('tr', field_content, :class => css).html_safe
          end
          
        end
                
        s << field_values
        s << '</table></form>'
        s.html_safe
      end

      private 
      def get_fields_for_project(project_id, available_custom_fields)
        all_fields = SubtaskListColumns.all.select {|c| c.prj_id == project_id}.sort_by{|o| o.order}
        available_fields = remove_unavailable_custom_fields(all_fields, available_custom_fields)
      end
      
      private 
      def remove_unavailable_custom_fields(fields_list, available_custom_fields)
        new_fields_list = Array.new
        fields_list.each do |field|
          id = field['ident'].to_i
          if(id == 0)
            # it is default, save it 
            new_fields_list.push(field)
          else
            if(available_custom_fields.detect {|f| f.id == id}.nil? == false)
              # there is custom field in projects' setting, save it
              new_fields_list.push(field)              
            end              
          end
        end
       return new_fields_list
      end
      
      private
      def get_first_column_in_table(child, has_traker, has_subject)
        content_tag('td', link_to_issue(child, :tracker=> has_traker, :subject => has_subject), :class => 'subject') 
      end
      
      private 
      def get_td(value)
        content_tag('td style="text-align:left"', value)
      end
    end
end


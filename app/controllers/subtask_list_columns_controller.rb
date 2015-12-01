require_dependency 'constants.rb' 

class SubtaskListColumnsController < ApplicationController
  unloadable
  
  def index   
    
    sql = "SELECT id, name FROM projects"
    @projects ||= ActiveRecord::Base.connection.select_all(sql)
    
    sql = "SELECT id as ident, name FROM custom_fields WHERE type = 'IssueCustomField'"
    customFields ||= ActiveRecord::Base.connection.select_all(sql)
    
    @allColumns = Constants::DEFAULT_FIELDS + customFields
    
    @selectedColumns = SubtaskListColumns.all
    
    save = params['save'].blank? ? '' : params['save']

    if (save.eql? '1')
      json = params['selectedColumns'].blank? ? '' : params['selectedColumns']
      
      if(json != '')
        updateSelectedColumns = JSON.parse(json)     
        
        SubtaskListColumns.delete_all()
        
        updateSelectedColumns.each do |col|
          c = SubtaskListColumns.new
          c.prj_id = col["prj_id"]
          c.ident = col["ident"]
          c.order = col["order"]
          c.save
          #TODO: do lazy save
        end   
      end
    end                                      
  end  
end

class CreateSubtaskListColumns < ActiveRecord::Migration
  def change
    create_table :subtask_list_columns do |t|
      t.integer :prj_id
      t.string :ident
      t.integer :order
    end
  end
  
   def down
    drop_table :subtask_list_columns
  end
end

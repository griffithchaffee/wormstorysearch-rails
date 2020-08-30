def up
  change_table :stories do |t|
    t.float :hype_rating, null: false, default: 0
  end
end

def down
  change_table :stories do |t|
    t.remove :hype_rating
  end
end

def migration_script
  Story.find_each(&:update_rating!)
end


#def up
#end
#def down
#end

#  create_table :table do |t|
#  end
#  change_table :table do |t|
#  end
#  drop_table :table

#    t.string  :column
#    t.text    :column
#    t.boolean :column
#    t.date    :column
#    t.remove  :column
#    t.rename  :column, :newcolumn
#    t.change_default  :column, default
#    t.timestamps null: false
#    t.change :column, :type OR "integer USING CAST(string_column AS integer)"
#    t.index :column_name

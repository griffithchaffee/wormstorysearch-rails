def up
  change_table :stories do |t|
    t.integer :clicks, null: false, default: 0
  end

  change_table :archiveofourown_stories do |t|
    t.integer :clicks, null: false, default: 0
  end

  change_table :fanfiction_stories do |t|
    t.integer :clicks, null: false, default: 0
  end

  change_table :questionablequesting_stories do |t|
    t.integer :clicks, null: false, default: 0
  end

  change_table :spacebattles_stories do |t|
    t.integer :clicks, null: false, default: 0
  end

  change_table :sufficientvelocity_stories do |t|
    t.integer :clicks, null: false, default: 0
  end
end

def down
  change_table :stories do |t|
    t.remove :clicks
  end

  change_table :archiveofourown_stories do |t|
    t.remove :clicks
  end

  change_table :fanfiction_stories do |t|
    t.remove :clicks
  end

  change_table :questionablequesting_stories do |t|
    t.remove :clicks
  end

  change_table :spacebattles_stories do |t|
    t.remove :clicks
  end

  change_table :sufficientvelocity_stories do |t|
    t.remove :clicks
  end
end

def migration_script
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

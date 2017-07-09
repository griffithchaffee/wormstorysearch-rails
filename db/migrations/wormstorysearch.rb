def up

  drop_table :old_stories

  change_table "stories", force: :cascade do |t|
    t.string "status", default: "ongoing", null: false
  end

  change_table "fanfiction_stories", force: :cascade do |t|
    t.string "status", default: "ongoing", null: false
  end
end

def down
  create_table("old_stories")
  change_table "stories", force: :cascade do |t|
    t.remove "status"
  end
  change_table "fanfiction_stories", force: :cascade do |t|
    t.remove "status"
  end
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

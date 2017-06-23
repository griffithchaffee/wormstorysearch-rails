def up
  change_table(:stories) do |t|
    t.boolean  :is_locked, null: false, default: false
  end
  create_table(:stories) do |t|
    t.string   :location,      null: false
    t.string   :location_id,   null: false
    t.string   :location_path, null: false
    t.string   :title,         null: false
    t.string   :author,        null: false
    t.string   :crossover
    t.string   :description
    t.integer  :word_count,       null: false, default: 0
    t.date     :story_created_on, null: false
    t.datetime :story_updated_at, null: false
    t.boolean  :is_locked, null: false, default: true
    t.timestamps null: false
  end

  create_table(:story_chapters) do |t|
    t.belongs_to :story,      null: false, index: true
    t.integer :position,      null: false
    t.string  :location_path, null: false
    t.string  :title,         null: false
    t.string  :category,      null: false, default: "chapter"
    t.integer :word_count,    null: false, default: 0
    t.datetime :chapter_created_at, null: false
    t.datetime :chapter_updated_at, null: false
    t.timestamps null: false
  end

  create_table "session_action_data", force: :cascade do |t|
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.string   "namespace",         null: false
    t.string   "session_id",        null: false
    t.text     "data_params",       null: false
    t.text     "pagination_params", null: false
    t.text     "search_params",     null: false
    t.index [:session_id, :namespace], unique: true
  end

  create_table "identity_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "session_id", null: false, index: { unique: true }
    t.text     "data"
  end
end

def down
  drop_table(:stories)
  drop_table(:story_chapters)
  drop_table(:session_action_data)
  drop_table(:identity_sessions)
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

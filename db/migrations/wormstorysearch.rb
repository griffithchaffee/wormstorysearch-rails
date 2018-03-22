def up
  change_table :story_authors do |t|
    t.string :questionablequesting_name
  end

  create_table "questionablequesting_stories", force: :cascade do |t|
    t.bigint "story_id"
    t.date "story_created_on", null: false
    t.datetime "created_at", null: false
    t.datetime "story_updated_at", null: false
    t.datetime "updated_at", null: false
    t.float "average_chapter_likes", default: 0.0, null: false
    t.index ["story_id"], name: "index_questionablequesting_stories_on_story_id"
    t.integer "highest_chapter_likes", default: 0, null: false
    t.integer "word_count", default: 0, null: false
    t.string "author_name", null: false
    t.string "category", default: "story", null: false
    t.string "location_id", null: false
    t.string "location_path", null: false
    t.string "read_url", null: false
    t.string "title", null: false
    t.boolean :is_nsfw, default: false, null: false
  end

  create_table "questionablequesting_story_chapters", force: :cascade do |t|
    t.bigint "story_id", null: false
    t.date "chapter_created_on", null: false
    t.datetime "chapter_updated_at", null: false
    t.datetime "created_at", null: false
    t.datetime "likes_updated_at"
    t.datetime "updated_at", null: false
    t.index ["story_id"], name: "index_questionablequesting_story_chapters_on_story_id"
    t.integer "likes", default: 0, null: false
    t.integer "position", null: false
    t.integer "word_count", default: 0, null: false
    t.string "category", default: "chapter", null: false
    t.string "location_path", null: false
    t.string "title", null: false
  end
end

def down
  change_table :story_authors do |t|
    t.remove :questionablequesting_name
  end
  drop_table "questionablequesting_stories"
  drop_table "questionablequesting_story_chapters"
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

def up

  drop_table "story_chapters"

  rename_table "stories", "old_stories"

  create_table "stories", force: :cascade do |t|
    t.boolean "is_locked", default: false, null: false
    t.boolean "is_archived", default: false, null: false
    t.date "story_created_on", null: false
    t.datetime "created_at", null: false
    t.datetime "story_updated_at", null: false
    t.datetime "updated_at", null: false
    t.integer "word_count", default: 0, null: false
    t.integer "likes", default: 0, null: false
    t.string "author", null: false
    t.string "title", null: false
    t.string "category", null: false, default: "story"
    t.string "crossover"
    t.string "description"
  end

  create_table "spacebattles_stories", force: :cascade do |t|
    t.bigint "story_id", index: true
    t.boolean "is_locked", default: false, null: false
    t.date "story_created_on", null: false
    t.datetime "created_at", null: false
    t.datetime "story_updated_at", null: false
    t.datetime "updated_at", null: false
    t.integer "word_count", default: 0, null: false
    t.integer "likes", default: 0, null: false
    t.string "author", null: false
    t.string "location_path", null: false
    t.string "location_id", null: false
    t.string "title", null: false
    t.string "read_url", null: false
    t.string "category", null: false, default: "story"
  end


  create_table "spacebattles_story_chapters", force: :cascade do |t|
    t.bigint "story_id", null: false, index: true
    t.date "chapter_created_on", null: false
    t.datetime "chapter_updated_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position", null: false
    t.integer "word_count", default: 0, null: false
    t.integer "likes", default: 0, null: false
    t.string "category", default: "chapter", null: false
    t.string "location_path", null: false
    t.string "title", null: false
  end

  create_table "sufficientvelocity_stories", force: :cascade do |t|
    t.bigint "story_id", index: true
    t.boolean "is_locked", default: false, null: false
    t.date "story_created_on", null: false
    t.datetime "created_at", null: false
    t.datetime "story_updated_at", null: false
    t.datetime "updated_at", null: false
    t.integer "word_count", default: 0, null: false
    t.integer "likes", default: 0, null: false
    t.string "author", null: false
    t.string "location_path", null: false
    t.string "location_id", null: false
    t.string "title", null: false
    t.string "read_url", null: false
    t.string "category", null: false, default: "story"
  end


  create_table "sufficientvelocity_story_chapters", force: :cascade do |t|
    t.bigint "story_id", null: false, index: true
    t.date "chapter_created_on", null: false
    t.datetime "chapter_updated_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position", null: false
    t.integer "word_count", default: 0, null: false
    t.integer "likes", default: 0, null: false
    t.string "category", default: "chapter", null: false
    t.string "location_path", null: false
    t.string "title", null: false
  end

  create_table "fanfiction_stories", force: :cascade do |t|
    t.bigint "story_id", index: true
    t.boolean "is_locked", default: false, null: false
    t.date "story_created_on", null: false
    t.datetime "created_at", null: false
    t.datetime "story_updated_at", null: false
    t.datetime "updated_at", null: false
    t.integer "word_count", default: 0, null: false
    t.integer "likes", default: 0, null: false
    t.string "author", null: false
    t.string "location_path", null: false
    t.string "location_id", null: false
    t.string "title", null: false
    t.string "read_url", null: false
    t.string "category", null: false, default: "story"
    t.string "crossover"
    t.text "description"
  end

  create_table "fanfiction_story_chapters", force: :cascade do |t|
    t.bigint "story_id", null: false, index: true
    t.date "chapter_created_on", null: false
    t.datetime "chapter_updated_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position", null: false
    t.integer "word_count", default: 0, null: false
    t.integer "likes", default: 0, null: false
    t.string "category", default: "chapter", null: false
    t.string "location_path", null: false
    t.string "title", null: false
  end
end

def down
  create_table("story_chapters")
  drop_table("stories")
  rename_table("old_stories", "stories")
  drop_table(:spacebattles_stories)
  drop_table(:spacebattles_story_chapters)
  drop_table(:sufficientvelocity_stories)
  drop_table(:sufficientvelocity_story_chapters)
  drop_table(:fanfiction_stories)
  drop_table(:fanfiction_story_chapters)
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
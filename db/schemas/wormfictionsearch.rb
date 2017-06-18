def change

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"


  create_table "stories", force: :cascade do |t|
    t.date "story_created_on", null: false
    t.datetime "created_at", null: false
    t.datetime "story_updated_at", null: false
    t.datetime "updated_at", null: false
    t.integer "word_count", null: false
    t.string "author", null: false
    t.string "location", null: false
    t.string "location_id", null: false
    t.string "location_url", null: false
    t.string "title", null: false
  end


  create_table "story_chapters", force: :cascade do |t|
    t.bigint "story_id", null: false
    t.datetime "chapter_created_at", null: false
    t.datetime "chapter_updated_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["story_id"], name: "index_story_chapters_on_story_id"
    t.integer "position", null: false
    t.integer "word_count", null: false
    t.string "location_url", null: false
    t.string "title", null: false
  end

end

def change

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"


  create_table "fanfiction_stories", force: :cascade do |t|
    t.bigint "story_id", null: false
    t.boolean "is_locked", default: false, null: false
    t.date "story_created_on", null: false
    t.datetime "created_at", null: false
    t.datetime "story_updated_at", null: false
    t.datetime "updated_at", null: false
    t.index ["story_id"], name: "index_fanfiction_stories_on_story_id"
    t.integer "likes", default: 0, null: false
    t.integer "word_count", default: 0, null: false
    t.string "author", null: false
    t.string "category", default: "story", null: false
    t.string "crossover"
    t.string "location_id", null: false
    t.string "location_path", null: false
    t.string "read_url", null: false
    t.string "title", null: false
    t.text "description"
  end


  create_table "fanfiction_story_chapters", force: :cascade do |t|
    t.bigint "story_id", null: false
    t.date "chapter_created_on", null: false
    t.datetime "chapter_updated_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["story_id"], name: "index_fanfiction_story_chapters_on_story_id"
    t.integer "likes", default: 0, null: false
    t.integer "position", null: false
    t.integer "word_count", default: 0, null: false
    t.string "category", default: "chapter", null: false
    t.string "location_path", null: false
    t.string "title", null: false
  end


  create_table "identity_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_identity_sessions_on_session_id", unique: true
    t.string "session_id", null: false
    t.text "data"
  end


  create_table "old_stories", force: :cascade do |t|
    t.boolean "is_locked", default: false, null: false
    t.date "story_created_on", null: false
    t.datetime "created_at", null: false
    t.datetime "story_updated_at", null: false
    t.datetime "updated_at", null: false
    t.integer "word_count", default: 0, null: false
    t.string "author", null: false
    t.string "crossover"
    t.string "description"
    t.string "location", null: false
    t.string "location_path", null: false
    t.string "location_story_id", null: false
    t.string "title", null: false
  end


  create_table "session_action_data", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id", "namespace"], name: "index_session_action_data_on_session_id_and_namespace", unique: true
    t.string "namespace", null: false
    t.string "session_id", null: false
    t.text "data_params", null: false
    t.text "pagination_params", null: false
    t.text "search_params", null: false
  end


  create_table "spacebattles_stories", force: :cascade do |t|
    t.bigint "story_id", null: false
    t.boolean "is_locked", default: false, null: false
    t.date "story_created_on", null: false
    t.datetime "created_at", null: false
    t.datetime "story_updated_at", null: false
    t.datetime "updated_at", null: false
    t.index ["story_id"], name: "index_spacebattles_stories_on_story_id"
    t.integer "likes", default: 0, null: false
    t.integer "word_count", default: 0, null: false
    t.string "author", null: false
    t.string "category", default: "story", null: false
    t.string "location_id", null: false
    t.string "location_path", null: false
    t.string "read_url", null: false
    t.string "title", null: false
  end


  create_table "spacebattles_story_chapters", force: :cascade do |t|
    t.bigint "story_id", null: false
    t.date "chapter_created_on", null: false
    t.datetime "chapter_updated_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["story_id"], name: "index_spacebattles_story_chapters_on_story_id"
    t.integer "likes", default: 0, null: false
    t.integer "position", null: false
    t.integer "word_count", default: 0, null: false
    t.string "category", default: "chapter", null: false
    t.string "location_path", null: false
    t.string "title", null: false
  end


  create_table "stories", force: :cascade do |t|
    t.boolean "is_archived", default: false, null: false
    t.boolean "is_locked", default: false, null: false
    t.date "story_created_on", null: false
    t.datetime "created_at", null: false
    t.datetime "story_updated_at", null: false
    t.datetime "updated_at", null: false
    t.integer "likes", default: 0, null: false
    t.integer "word_count", default: 0, null: false
    t.string "author", null: false
    t.string "category", default: "story", null: false
    t.string "crossover"
    t.string "description"
    t.string "title", null: false
  end


  create_table "sufficientvelocity_stories", force: :cascade do |t|
    t.bigint "story_id", null: false
    t.boolean "is_locked", default: false, null: false
    t.date "story_created_on", null: false
    t.datetime "created_at", null: false
    t.datetime "story_updated_at", null: false
    t.datetime "updated_at", null: false
    t.index ["story_id"], name: "index_sufficientvelocity_stories_on_story_id"
    t.integer "likes", default: 0, null: false
    t.integer "word_count", default: 0, null: false
    t.string "author", null: false
    t.string "category", default: "story", null: false
    t.string "location_id", null: false
    t.string "location_path", null: false
    t.string "read_url", null: false
    t.string "title", null: false
  end


  create_table "sufficientvelocity_story_chapters", force: :cascade do |t|
    t.bigint "story_id", null: false
    t.date "chapter_created_on", null: false
    t.datetime "chapter_updated_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["story_id"], name: "index_sufficientvelocity_story_chapters_on_story_id"
    t.integer "likes", default: 0, null: false
    t.integer "position", null: false
    t.integer "word_count", default: 0, null: false
    t.string "category", default: "chapter", null: false
    t.string "location_path", null: false
    t.string "title", null: false
  end

end

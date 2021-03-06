def change

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"


  create_table "archiveofourown_stories", force: :cascade do |t|
    t.bigint "story_id"
    t.boolean "is_nsfw", default: false, null: false
    t.date "story_created_on", null: false
    t.datetime "created_at", null: false
    t.datetime "kudos_updated_at"
    t.datetime "story_updated_at", null: false
    t.datetime "updated_at", null: false
    t.index ["story_id"], name: "index_archiveofourown_stories_on_story_id"
    t.integer "clicks", default: 0, null: false
    t.integer "kudos", default: 0, null: false
    t.integer "word_count", default: 0, null: false
    t.string "author_name", null: false
    t.string "category", default: "story", null: false
    t.string "crossover"
    t.string "location_id", null: false
    t.string "location_path", null: false
    t.string "read_url", null: false
    t.string "status", default: "ongoing", null: false
    t.string "title", null: false
    t.text "description"
  end


  create_table "archiveofourown_story_chapters", force: :cascade do |t|
    t.bigint "story_id", null: false
    t.date "chapter_created_on", null: false
    t.datetime "chapter_updated_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["story_id"], name: "index_archiveofourown_story_chapters_on_story_id"
    t.integer "position", null: false
    t.integer "word_count", default: 0, null: false
    t.string "category", default: "chapter", null: false
    t.string "location_path", null: false
    t.string "title", null: false
  end


  create_table "fanfiction_stories", force: :cascade do |t|
    t.bigint "story_id"
    t.date "story_created_on", null: false
    t.datetime "created_at", null: false
    t.datetime "favorites_updated_at"
    t.datetime "story_updated_at", null: false
    t.datetime "updated_at", null: false
    t.index ["story_id"], name: "index_fanfiction_stories_on_story_id"
    t.integer "clicks", default: 0, null: false
    t.integer "favorites", default: 0, null: false
    t.integer "word_count", default: 0, null: false
    t.string "author_name", null: false
    t.string "category", default: "story", null: false
    t.string "crossover"
    t.string "location_id", null: false
    t.string "location_path", null: false
    t.string "read_url", null: false
    t.string "status", default: "ongoing", null: false
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


  create_table "questionablequesting_stories", force: :cascade do |t|
    t.bigint "story_id"
    t.boolean "is_nsfw", default: false, null: false
    t.date "story_created_on", null: false
    t.datetime "created_at", null: false
    t.datetime "story_updated_at", null: false
    t.datetime "updated_at", null: false
    t.float "average_chapter_likes", default: 0.0, null: false
    t.index ["story_id"], name: "index_questionablequesting_stories_on_story_id"
    t.integer "clicks", default: 0, null: false
    t.integer "highest_chapter_likes", default: 0, null: false
    t.integer "word_count", default: 0, null: false
    t.string "author_name", null: false
    t.string "category", default: "story", null: false
    t.string "location_id", null: false
    t.string "location_path", null: false
    t.string "read_url", null: false
    t.string "title", null: false
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
    t.bigint "story_id"
    t.date "story_created_on", null: false
    t.datetime "created_at", null: false
    t.datetime "story_updated_at", null: false
    t.datetime "updated_at", null: false
    t.float "average_chapter_likes", default: 0.0, null: false
    t.index ["story_id"], name: "index_spacebattles_stories_on_story_id"
    t.integer "clicks", default: 0, null: false
    t.integer "highest_chapter_likes", default: 0, null: false
    t.integer "word_count", default: 0, null: false
    t.string "author_name", null: false
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
    t.datetime "likes_updated_at"
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
    t.bigint "author_id"
    t.boolean "is_archived", default: false, null: false
    t.boolean "is_nsfw", default: false, null: false
    t.date "story_created_on", null: false
    t.datetime "created_at", null: false
    t.datetime "story_updated_at", null: false
    t.datetime "updated_at", null: false
    t.float "hype_rating", default: 0.0, null: false
    t.float "rating", default: 0.0, null: false
    t.index ["author_id"], name: "index_stories_on_author_id"
    t.integer "clicks", default: 0, null: false
    t.integer "word_count", default: 0, null: false
    t.string "category", default: "story", null: false
    t.string "crossover"
    t.string "description"
    t.string "status", default: "ongoing", null: false
    t.string "title", null: false
  end


  create_table "story_authors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "archiveofourown_name"
    t.string "fanfiction_name"
    t.string "name", null: false
    t.string "questionablequesting_name"
    t.string "spacebattles_name"
    t.string "sufficientvelocity_name"
  end


  create_table "sufficientvelocity_stories", force: :cascade do |t|
    t.bigint "story_id"
    t.date "story_created_on", null: false
    t.datetime "created_at", null: false
    t.datetime "story_updated_at", null: false
    t.datetime "updated_at", null: false
    t.float "average_chapter_likes", default: 0.0, null: false
    t.index ["story_id"], name: "index_sufficientvelocity_stories_on_story_id"
    t.integer "clicks", default: 0, null: false
    t.integer "highest_chapter_likes", default: 0, null: false
    t.integer "word_count", default: 0, null: false
    t.string "author_name", null: false
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
    t.datetime "likes_updated_at"
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

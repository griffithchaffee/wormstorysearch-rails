def up
  change_table "stories", force: :cascade do |t|
    t.remove :likes
    t.float :rating, null: false, default: 0, precision: 2
  end

  change_table "fanfiction_stories", force: :cascade do |t|
    t.integer :favorites, null: false, default: 0
    t.remove :likes
  end

  change_table "fanfiction_story_chapters", force: :cascade do |t|
    t.remove "likes"
  end

  change_table "spacebattles_stories", force: :cascade do |t|
    t.remove :likes
    t.float :average_chapter_likes, null: false, default: 0, precision: 2
  end

  change_table "sufficientvelocity_stories", force: :cascade do |t|
    t.remove :likes
    t.float :average_chapter_likes, null: false, default: 0, precision: 2
  end
end

def down
  change_table "stories", force: :cascade do |t|
    t.integer :likes
    t.remove :rating
  end

  change_table "fanfiction_stories", force: :cascade do |t|
    t.remove :favorites
    t.integer :likes
  end

  change_table "fanfiction_story_chapters", force: :cascade do |t|
    t.integer "likes"
  end

  change_table "spacebattles_stories", force: :cascade do |t|
    t.integer :likes
    t.remove :average_chapter_likes
  end

  change_table "sufficientvelocity_stories", force: :cascade do |t|
    t.integer :likes
    t.remove :average_chapter_likes
  end
end

def migration_script
  SpacebattlesStoryChapter.find_each do |chapter|
    new_location_path = "/#{chapter.location_path}" if !chapter.location_path.starts_with?("/")
    chapter.update_columns(location_path: new_location_path) if new_location_path
  end
  SufficientvelocityStoryChapter.find_each do |chapter|
    new_location_path = "/#{chapter.location_path}" if !chapter.location_path.starts_with?("/")
    chapter.update_columns(location_path: new_location_path) if new_location_path
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

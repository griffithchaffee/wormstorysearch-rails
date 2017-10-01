def up
  change_table "spacebattles_stories" do |t|
    t.integer :highest_chapter_likes, null: false, default: 0
  end

  change_table "spacebattles_story_chapters" do |t|
    t.datetime :likes_updated_at
  end

  change_table "sufficientvelocity_stories" do |t|
    t.integer :highest_chapter_likes, null: false, default: 0
  end

  change_table "sufficientvelocity_story_chapters" do |t|
    t.datetime :likes_updated_at
  end

  change_table "fanfiction_stories" do |t|
    t.datetime :favorites_updated_at
  end
end

def down
  change_table "spacebattles_stories" do |t|
    t.remove :highest_chapter_likes
  end

  change_table "spacebattles_story_chapters" do |t|
    t.remove :likes_updated_at
  end

  change_table "sufficientvelocity_stories" do |t|
    t.remove :highest_chapter_likes
  end

  change_table "sufficientvelocity_story_chapters" do |t|
    t.remove :likes_updated_at
  end

  change_table "fanfiction_stories" do |t|
    t.remove :favorites_updated_at
  end
end

def migration_script
  SpacebattlesStoryChapter.seek(likes_not_eq: 0, likes_updated_at_eq: nil).update_all(likes_updated_at: DateTime.parse("2017-08-15"))
  SufficientvelocityStoryChapter.seek(likes_not_eq: 0, likes_updated_at_eq: nil).update_all(likes_updated_at: DateTime.parse("2017-08-15"))
  FanfictionStory.seek(favorites_not_eq: 0, favorites_updated_at_eq: nil).update_all(favorites_updated_at: DateTime.parse("2017-08-15"))
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

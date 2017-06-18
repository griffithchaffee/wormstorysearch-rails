def up
  create_table(:stories) do |t|
    t.string   :location,      null: false
    t.string   :location_id,   null: false
    t.string   :location_url,  null: false
    t.string   :title,         null: false
    t.string   :author,        null: false
    t.integer  :word_count,    null: false
    t.date     :story_created_on, null: false
    t.datetime :story_updated_at, null: false
    t.timestamps null: false
  end

  create_table(:story_chapters) do |t|
    t.belongs_to :story,     null: false
    t.integer :position,     null: false
    t.string  :location_url, null: false
    t.string  :title,        null: false
    t.integer :word_count,   null: false
    t.datetime :chapter_created_at, null: false
    t.datetime :chapter_updated_at, null: false
    t.timestamps null: false
  end
end

def down
  drop_table(:stories)
  drop_table(:story_chapters)
end

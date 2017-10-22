def up
  change_table :spacebattles_stories do |t|
    t.rename :author, :author_name
  end

  change_table :sufficientvelocity_stories do |t|
    t.rename :author, :author_name
  end

  change_table :fanfiction_stories do |t|
    t.rename :author, :author_name
  end

  change_table :stories do |t|
    t.remove :author
    t.belongs_to :author, index: true
  end

  create_table "story_authors" do |t|
    t.string :name, null: false
    t.string :spacebattles_name
    t.string :sufficientvelocity_name
    t.string :fanfiction_name
    t.timestamps(null: false)
  end
end

def down
  change_table :spacebattles_stories do |t|
    t.rename :author_name, :author
  end

  change_table :sufficientvelocity_stories do |t|
    t.rename :author_name, :author
  end

  change_table :fanfiction_stories do |t|
    t.rename :author_name, :author
  end

  change_table :stories do |t|
    t.string :author
    t.remove :author_id
  end

  drop_table :story_authors
end

def migration_script
  Story.location_models.each do |location_model|
    location_model.all.each do |story|
      story.author_name = story.author_name
      begin
        story.save!
      rescue StandardError => error
        puts error.inspect
        puts story.inspect
        raise error
      end
    end
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

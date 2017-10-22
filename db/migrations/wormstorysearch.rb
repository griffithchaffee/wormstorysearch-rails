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
  Rails.logger.level = Logger::INFO
  Story.const.location_models.preload(:story).each do |location_model|
    location_model.all.each do |location_story|
      begin
        location_story.author_name = location_story.author_name # normalize
        location_story.save!
        location_story.author!
        location_story.story.author_name
      rescue StandardError => error
        puts "
          location_story: #{location_story.inspect}
          #{errors.class}: #{error.messsage}
          #{error.backtrace.join("\n")}
        ".strip
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

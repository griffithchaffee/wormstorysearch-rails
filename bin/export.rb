require 'csv'

# Story
builder = {
"Id"          => -> (story) { story.id },
"Title"       => -> (story) { story.title },
"Crossover"   => -> (story) { story.crossover },
"Author"      => -> (story) { story.author.name },
"Rating"      => -> (story) { story.rating },
"Word Count"  => -> (story) { story.word_count },
"Created On"  => -> (story) { story.story_created_on.iso8601 },
"Updated At"  => -> (story) { story.story_updated_at.iso8601 },
"Status"      => -> (story) { story.status },
"NSFW"        => -> (story) { story.is_nsfw? },
"Description" => -> (story) { story.description },
"Latest URL"  => -> (story) { story.read_url },
}

stories_csv = CSV.generate(force_quotes: true, headers: true) do |csv|
  csv << builder.keys
  Story.preload(:author).preload_locations.all.each do |story|
    csv << builder.values.map { |value_proc| value_proc.call(story) }
  end
end

File.open("#{Rails.root}/public/assets/stories.csv", "w") { |file| file.write(stories_csv) }

# SpacebattlesStory
builder = {
"Story Id"    => -> (story) { story.story_id },
"Title"       => -> (story) { story.title },
"Author"      => -> (story) { story.author_name },
"Category"    => -> (story) { story.category },
"Average Chapter Likes" => -> (story) { story.average_chapter_likes },
"Highest Chapter Likes" => -> (story) { story.highest_chapter_likes },
"Word Count"  => -> (story) { story.word_count },
"Created On"  => -> (story) { story.story_created_on.iso8601 },
"Updated At"  => -> (story) { story.story_updated_at.iso8601 },
"URL"         => -> (story) { story.read_url },
}

spacebattles_stories_csv = CSV.generate(force_quotes: true, headers: true) do |csv|
  csv << builder.keys
  SpacebattlesStory.all.each do |story|
    csv << builder.values.map { |value_proc| value_proc.call(story) }
  end
end

File.open("#{Rails.root}/public/assets/spacebattles_stories.csv", "w") { |file| file.write(spacebattles_stories_csv) }

# SufficientvelocityStory
builder = {
"Story Id"    => -> (story) { story.story_id },
"Title"       => -> (story) { story.title },
"Author"      => -> (story) { story.author_name },
"Category"    => -> (story) { story.category },
"Average Chapter Likes" => -> (story) { story.average_chapter_likes },
"Highest Chapter Likes" => -> (story) { story.highest_chapter_likes },
"Word Count"  => -> (story) { story.word_count },
"Created On"  => -> (story) { story.story_created_on.iso8601 },
"Updated At"  => -> (story) { story.story_updated_at.iso8601 },
"URL"         => -> (story) { story.read_url },
}

sufficientvelocity_stories_csv = CSV.generate(force_quotes: true, headers: true) do |csv|
  csv << builder.keys
  SufficientvelocityStory.all.each do |story|
    csv << builder.values.map { |value_proc| value_proc.call(story) }
  end
end

File.open("#{Rails.root}/public/assets/sufficientvelocity_stories.csv", "w") { |file| file.write(sufficientvelocity_stories_csv) }


# FanfictionStory
builder = {
"Story Id"    => -> (story) { story.story_id },
"Title"       => -> (story) { story.title },
"Crossover"   => -> (story) { story.crossover },
"Author"      => -> (story) { story.author_name },
"Category"    => -> (story) { story.category },
"Favorites"   => -> (story) { story.favorites },
"Word Count"  => -> (story) { story.word_count },
"Created On"  => -> (story) { story.story_created_on.iso8601 },
"Updated At"  => -> (story) { story.story_updated_at.iso8601 },
"URL"         => -> (story) { story.read_url },
}

fanfiction_stories_csv = CSV.generate(force_quotes: true, headers: true) do |csv|
  csv << builder.keys
  FanfictionStory.all.each do |story|
    csv << builder.values.map { |value_proc| value_proc.call(story) }
  end
end

File.open("#{Rails.root}/public/assets/fanfiction_stories.csv", "w") { |file| file.write(fanfiction_stories_csv) }


# ArchiveofourownStory
builder = {
"Story Id"    => -> (story) { story.story_id },
"Title"       => -> (story) { story.title },
"Crossover"   => -> (story) { story.crossover },
"Author"      => -> (story) { story.author_name },
"Category"    => -> (story) { story.category },
"Kudos"       => -> (story) { story.kudos },
"Word Count"  => -> (story) { story.word_count },
"Created On"  => -> (story) { story.story_created_on.iso8601 },
"Updated At"  => -> (story) { story.story_updated_at.iso8601 },
"NSFW"        => -> (story) { story.is_nsfw? },
"URL"         => -> (story) { story.read_url },
}

archiveofourown_stories_csv = CSV.generate(force_quotes: true, headers: true) do |csv|
  csv << builder.keys
  ArchiveofourownStory.all.each do |story|
    csv << builder.values.map { |value_proc| value_proc.call(story) }
  end
end

File.open("#{Rails.root}/public/assets/archiveofourown_stories.csv", "w") { |file| file.write(archiveofourown_stories_csv) }



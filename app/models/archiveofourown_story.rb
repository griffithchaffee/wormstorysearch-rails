class ArchiveofourownStory < ApplicationRecord
  # modules/constants
  include LocationStoryConcern

  # associations/scopes/validations/callbacks/macros
  before_validation do
    if will_save_change_to_kudos? && kudos > 0
      self.kudos_updated_at = Time.zone.now
    end
  end

  after_create do
    if story
      # overwrite crossover
      if crossover? && !story.crossover?
        story.crossover = crossover_for_story
      end
      # default description
      if description? && !story.description?
        story.description = description
      end
      # is_nsfw
      if is_nsfw? && !story.is_nsfw?
        story.is_nsfw = is_nsfw?
      end
      story.save! if story.has_changes_to_save?
    end
  end

  after_update do
    # nsfw
    if saved_change_to_is_nsfw? && is_nsfw? && !story.is_nsfw?
      story.update!(is_nsfw: is_nsfw?)
    end
  end

  # public/private/protected/classes
  def read_url!
    chapters.size.in?([0, 1]) ? location_url : "#{location_url}/navigate"
  end

  def update_rating!(searcher: LocationSearcher::ArchiveofourownSearcher.new)
    searcher.update_story_kudos!(self)
    self
  rescue StandardError => error
    update_columns(kudos_updated_at: Time.zone.now)
    raise(error)
    self
  end

  def crossover_for_story
    return nil if !crossover?
    formatted_crossover = crossover
    # "Pocket Monsters | Pokemon" => "Pokemon"
    # "ゼロの使い魔 | Zero no Tsukaima | The Familiar of Zero" => "The Familiar of Zero"
    if formatted_crossover.include?(" | ")
      # select english part
      formatted_crossover = formatted_crossover.split(" | ").select { |part| part =~ /[A-Za-z]/ }.last
      return nil if formatted_crossover.blank?
    end
    # "Assassin's Creed - All Media Types" => "Assassin's Creed"
    if formatted_crossover.include?(" - ")
      formatted_crossover = formatted_crossover.split(" - ")[0..-2].join(" - ")
    end
    # "XCOM (Video Games) & Related Fandoms" => "XCOM (Video Games)"
    if formatted_crossover.include?(" & ")
      formatted_crossover = formatted_crossover.split(" & ")[0..-2].join(" & ")
    end
    # "DCU (Comics)" => "DCU"
    if formatted_crossover.include?("(")
      formatted_crossover = formatted_crossover.remove(/\([^)]*\)/)
    end
    return nil if formatted_crossover.blank?
    formatted_crossover = formatted_crossover.strip
    exclude_crossovers = ["Worm"]
    return nil if formatted_crossover.in?(exclude_crossovers)
    formatted_crossover
  end

end

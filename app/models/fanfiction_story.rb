class FanfictionStory < ApplicationRecord
  # modules/constants
  include LocationStoryConcern

  # load settings
  class_constant_builder(:statuses, %w[ status label ]) do |new_const|
    new_const.add(status: "ongoing",  label: "Ongoing")
    new_const.add(status: "complete", label: "Complete")
  end

  # associations/scopes/validations/callbacks/macros
  validates_in_list(:status, const.statuses.map(&:status))

  before_validation do
    if will_save_change_to_favorites? && favorites > 0
      self.favorites_updated_at = Time.zone.now
    end
  end

  after_create do
    if story
      # overwrite crossover
      if crossover? && story.crossover != crossover_for_story
        story.crossover = crossover_for_story
      end
      # default description
      if !story.description? && story.description != description
        story.description = description
      end
      story.save! if story.has_changes_to_save?
    end
  end

  # public/private/protected/classes
  def read_url!
    chapters.present? ? chapters.sort.last.location_url : location_url
  end

  def update_rating!(searcher: LocationSearcher::FanfictionSearcher.new)
    searcher.update_story_favorites!(self)
    self
  rescue StandardError => error
    update_columns(favorites_updated_at: Time.zone.now)
    raise(error)
    self
  end

  def crossover_for_story
    return nil if !crossover?
    formatted_crossover = crossover
    formatted_crossover = formatted_crossover.remove(/\AWorm & | & Worm\z/)
    if formatted_crossover.include?("/")
      formatted_crossover = formatted_crossover.split("/").select { |part| part =~ /[A-Za-z]/ }.join("/")
    end
    formatted_crossover = formatted_crossover.strip
    return nil if formatted_crossover.blank?
    exclude_crossovers = ["Web Shows"]
    return nil if formatted_crossover.in?(exclude_crossovers)
    # "Anime X-overs", "Book X-overs"
    return nil if formatted_crossover.ends_with?("X-overs")
    # "Misc. Books", "Misc. Comics"
    return nil if formatted_crossover.starts_with?("Misc. ")
    formatted_crossover
  end

end

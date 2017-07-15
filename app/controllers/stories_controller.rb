class StoriesController < ApplicationController

  def show
  end

  def edit
  end

  def update
    if @story.is_locked?
      flash.info("#{@story.title} has been locked can no longer be updated")
    else
      @story.assign_attributes(permitted_action_story_params)
      if @story.save
        flash.notice("Successfully updated: #{@story.title} by #{@story.author}")
      else
        flash.alert("There was a problem while trying to update #{@story.title}:\n#{@story.errors.full_messages.join("\n")}")
      end
    end
    redirect_to(stories_path)
  end

  def index
    # preload chapters because read_url requires them
    @stories = Story.preload_locations
      .search(permitted_action_search_params(save: true).to_unsafe_h, is_archived_eq: false)
      .order_story_updated_at(:desc)
      .paginate(permitted_action_pagination_params(save: true).to_unsafe_h, limit: 15)
  end

private

  generate_permitted_record_params
  before_action :set_story, only: %w[ show edit update ]

  def set_story
    @story ||= Story.find(params[:id])
  end

  def permit_story_params
    permit = %w[ title author crossover description status ]
    permit += %w[ is_locked is_archived ] if is_admin?
    permit
  end

  def permit_index_search_params
    %w[
      story_keywords category_eq story_updated_at_gteq is_archived_eq is_locked_eq word_count_gteq status_eq
      sort direction
    ]
  end

end

class StoriesController < ApplicationController

  def index
    # preload chapters because read_url requires them
    @stories = Story.preload_locations
      .search(permitted_action_search_params(save: true).to_unsafe_h, is_archived_eq: false)
      .order_story_updated_at(:desc)
      .paginate(permitted_action_pagination_params(save: true).to_unsafe_h, limit: 15)
  end

  def show
  end

  def edit
  end

  def update
    @story.assign_attributes(permitted_action_story_params)
    if @story.save
      flash.notice("Successfully updated: #{@story.crossover_title}")
    else
      flash.alert("There was a problem while trying to update #{@story.crossover_title}:\n#{@story.errors.full_messages.join("\n")}")
    end
    redirect_to(stories_path)
  end

private

  generate_permitted_record_params
  before_action :admin_only_action, only: %w[ edit update ]
  before_action :set_story, only: %w[ show edit update ]

  def set_story
    @story ||= Story.find(params[:id])
  end

  def permit_story_params
    permit = %w[ title author_id crossover description status ]
    permit += %w[ is_locked is_archived ] if is_admin?
    permit
  end

  def permit_index_search_params
    %w[
      category_eq story_updated_at_gteq is_archived_eq is_locked_eq status_eq
      story_keywords word_count_filter rating_filter
      sort direction
    ]
  end

end

class StoriesController < ApplicationController

  def index
    # preload chapters because read_url requires them
    @stories = Story.preload_locations.preload(:author)
      .search(permitted_action_search_params(save: true).to_unsafe_h, is_archived_eq: "false", is_nsfw_eq: "false")
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
    # merge with story
    if params[:merge_with_story_id].present?
      duplicate_story = Story.find_by(id: params[:merge_with_story_id])
      @story.merge_with_story!(duplicate_story) if duplicate_story
    end
    redirect_to(stories_path)
  end

  def clicked
    story = Story.find_by(id: params[:id])
    if story
      story.increment!(:clicks)
      if params[:location_model] && params[:location_id]
        location_model = params[:location_model].to_s.classify.constantize
        location_story = location_model.find_by(id: params[:location_id])
        location_story.increment!(:clicks) if location_story
      end
    end
    render(inline: "clicked")
  end

private

  generate_permitted_record_params
  before_action :admin_only_action, only: %w[ edit update ]
  before_action :set_story, only: %w[ show edit update ]

  def set_story
    @story ||= Story.preload_locations.preload(:author).find(params[:id])
  end

  def permit_story_params
    if is_admin?
      %w[ title author_id crossover description status is_archived is_nsfw ]
    else
      []
    end
  end

  def permit_index_search_params
    %w[
      category_eq status_eq is_nsfw_eq is_archived_eq
      story_keywords word_count_filter rating_filter hype_rating_filter
      updated_after_filter updated_before_filter location_slug_in
      sort direction
    ]
  end

end

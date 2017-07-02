class StoriesController < ApplicationController

  def show
    view_layout.verify_is!("modal")
  end

  def edit
    view_layout.verify_is!("modal")
  end

  def update
    if @story.is_locked?
      flash.info("#{@story.title} has been locked can no longer be updated")
    else
      @story.assign_attributes(permitted_action_story_params)
      if @story.save
        flash.notice("Successfully updated #{@story.title}")
      else
        flash.alert("There was a problem while trying to update #{@story.title}:\n#{@story.errors.full_messages.join("\n")}")
      end
    end
    redirect_to(stories_path)
  end

  def index
    # preload chapters because read_url requires them
    @stories = Story.preload(:spacebattles_stories, :sufficientvelocity_stories, :fanfiction_stories)
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
    permit = %w[ title author crossover description ]
    permit += %w[ is_locked is_archived ] if is_admin?
    permit
  end

  def permit_index_search_params
    %w[
      story_matches category_eq story_updated_at_gteq is_archived_eq is_locked_eq
      sort direction
    ]
  end

end

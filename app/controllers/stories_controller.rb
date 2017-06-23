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
    @stories = Story.preload(:chapters)
      .search(permitted_action_search_params(save: true))
      .order_story_updated_at(:desc)
      .paginate(permitted_action_pagination_params(save: true))
  end

private

  generate_permitted_record_params
  before_action :set_story, only: %w[ show edit update ]

  def set_story
    @story ||= Story.find(params[:id])
  end

  def permit_story_params
    %w[ crossover description is_locked ]
  end

  def permit_index_search_params
    %w[
      title_matches story_updated_at_gteq
      sort direction
    ]
  end

end

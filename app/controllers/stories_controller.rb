class StoriesController < ApplicationController

  def show
    @story = Story.find(params[:id])
  end

  def index
    @stories = Story
      .search(permitted_action_search_params(save: true))
      .paginate(permitted_action_pagination_params(save: true))
  end

private

  def permit_index_search_params
    %w[
      title_matches story_updated_at_gteq
      sort direction
    ]
  end

end

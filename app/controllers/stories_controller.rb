class StoriesController < ApplicationController

  def index
    @stories = Story.search(permitted_index_search_params)
  end

private

  def permitted_index_search_params
    params.permit(*%w[ title_matches ]).to_h
  end

end

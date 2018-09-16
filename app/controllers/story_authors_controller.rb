class StoryAuthorsController < ApplicationController

  def index
    @story_authors = StoryAuthor.all
      .search(permitted_action_search_params(save: true).to_unsafe_h)
      .order_name
      .paginate(permitted_action_pagination_params(save: true).to_unsafe_h, limit: 15)
  end

  def edit
    view_layout.verify_is!(:modal)
  end

  def update
    @story_author.assign_attributes(permitted_action_story_author_params)
    if @story_author.save
      flash.notice("Successfully updated author: #{@story_author.name.inspect}")
    else
      flash.alert("There was a problem while trying to update author #{@story_author.name.inspect}:\n#{@story_author.errors.full_messages.join("\n")}")
    end
    # merge with author
    if params[:merge_with_author_id].present?
      duplicate_author = StoryAuthor.find_by(id: params[:merge_with_author_id])
      @story_author.merge_with_author!(duplicate_author) if duplicate_author
    end
    redirect_to(story_authors_path)
  end

  def destroy
    @story_author.destroy!
    flash.notice("Successfully deleted author: #{@story_author.name.inspect}")
    redirect_to(story_authors_path)
  end

private

  generate_permitted_record_params
  before_action :admin_only_action, only: %w[ edit update destroy ]
  before_action :set_story_author, only: %w[ edit update destroy ]

  def set_story_author
    @story_author ||= StoryAuthor.find(params[:id])
  end

  def permit_story_author_params
    %w[ name spacebattles_name sufficientvelocity_name fanfiction_name archiveofourown_name questionablequesting_name ]
  end

  def permit_index_search_params
    %w[
      any_name_matches
      sort direction
    ]
  end

end

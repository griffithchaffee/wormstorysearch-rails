class ApplicationRecord < ApplicationDatabase

  extend ClassOptionsAttribute
  include SeekConcern
  include ValidationConcern

  self.abstract_class = true

  def saved?
    !new_record?
  end

  def exists?
    saved?
  end

  def unsaved?
    !saved?
  end

  def has_errors?
    errors.present?
  end

  def has_no_errors?
    !has_errors?
  end

  delegate *%w[ table_name singular_slug plural_slug ], to: :class

  class << self
    def none?
      !exists?
    end

    def singular_slug
      name.underscore
    end

    def plural_slug
      singular_slug.pluralize
    end
  end
end

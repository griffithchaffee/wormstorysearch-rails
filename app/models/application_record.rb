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

  delegate *%w[ table_name class_name class_slug controller_slug controller ], to: :class

  module ClassMethods
    def class_name
      name
    end

    def class_slug
      class_name.slugify
    end

    def controller_slug
      class_slug.pluralize
    end

    def controller
      "#{controller_slug}_controller".classify.constantize
    end

    def none?
      !exists?
    end
  end
end

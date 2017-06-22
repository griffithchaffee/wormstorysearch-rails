class SessionActionData < ApplicationRecord
  # modules/constants
  serialized_attributes = %w[ data_params search_params pagination_params ]

  # associations/scopes/validations/callbacks/macros
  belongs_to :identity_session, foreign_key: :session_id, primary_key: :session_id

  generate_column_scopes

  validates_presence_of_required_columns(exclude: serialized_attributes)

  serialized_attributes.each do |attribute|
    validates_is_not_nil(attribute)
    serialize(attribute)
  end

  before_validation do
    serialized_attributes.each do |attribute|
      send("#{attribute}=", send(attribute)) if self[attribute].nil?
    end
  end

  # public/private/protected/classes
  serialized_attributes.each do |attribute|
    define_method("#{attribute}=") { |hash| self[attribute] = hash.to_h.with_indifferent_access }
    define_method(attribute) do
      if self[attribute].is_a?(ActiveSupport::HashWithIndifferentAccess)
        self[attribute]
      else
        self[attribute] = self[attribute].to_h.with_indifferent_access
      end
    end
  end
end

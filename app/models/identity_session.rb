class IdentitySession < ApplicationRecord

  # associations/scopes/validations/callbacks/macros
  serialize(:data)

  generate_column_scopes

  validates_presence_of_required_columns(exclude: :data)

  validates_is_not_nil(:data)

  before_validation do
    send("data=", data) if self[:data].nil?
  end

  # public/private/protected/classes
  def initialize(attributes_hash, options_hash = {})
    Rails.logger.fatal { "IdentitySession.new(#{attributes_hash}, #{options_hash})" }
    raise "session options_hash: #{options_hash.inspect}" if options_hash.present?
    super(attributes_hash.to_h)
  end

  define_method("data=") { |hash| self[:data] = hash.to_h.with_indifferent_access }
  define_method(:data) { (self[:data] || {}).to_h.with_indifferent_access }

end


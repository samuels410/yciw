class Favorite < ActiveRecord::Base
  belongs_to :context, polymorphic: [:course, :group]
  validates_inclusion_of :context_type, :allow_nil => true, :in => ['Course', 'Group'].freeze
  scope :by, lambda { |type| where(:context_type => type) }
  attr_accessible :context, :context_id, :context_type
end

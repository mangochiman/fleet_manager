# app/models/application_record.rb
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # PaperTrail configuration
  def self.current_user=(user)
    PaperTrail.request.whodunnit = user&.id
    Current.user = user if defined?(Current)
  end

  def self.current_user
    Current.user if defined?(Current)
  end
end
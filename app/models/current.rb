class Current < ActiveSupport::CurrentAttributes
  attribute :ip_address, :user_agent, :current_user
end

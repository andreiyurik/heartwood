class GettingStartedController < ApplicationController
  def destroy
    Current.membership.update!(getting_started_hidden_at: Time.current)
    redirect_to people_path
  end
end

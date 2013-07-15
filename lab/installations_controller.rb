require File.join(File.dirname(__FILE__), *%w[schedule_installation])
require File.join(File.dirname(__FILE__), *%w[responder])
class InstallationsController < ActionController::Base
  # lots more stuff...

  def schedule
    audit_trail_for(current_user) do
      ScheduleInstallation.new(self, @installation, @city).call
    end
  end

  # lots more stuff...
end

require File.join(File.dirname(__FILE__), *%w[schedule_installation])
require File.join(File.dirname(__FILE__), *%w[responder])
class InstallationsController < ActionController::Base
  # lots more stuff...

  def schedule
    audit_trail_for(current_user) do
      desired_date = params[:desired_date]
      installation_type = params[:installation_type]
      ScheduleInstallation.new(self, @installation, @city, desired_date, installation_type).call
    end
  end

  # lots more stuff...
end

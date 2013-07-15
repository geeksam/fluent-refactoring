require File.join(File.dirname(__FILE__), *%w[schedule_installation])
require File.join(File.dirname(__FILE__), *%w[responder])
class InstallationsController < ActionController::Base
  # lots more stuff...

  def schedule
    ScheduleInstallation.new(self, @installation, @city).call
  end

  # lots more stuff...
end

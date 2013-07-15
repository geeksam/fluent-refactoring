class ScheduleInstallation
  def initialize(responder, installation, city, desired_date, installation_type)
    @responder = responder
    @installation = installation
    @city = city
    @desired_date = desired_date
    @installation_type = installation_type
  end

  def call
    if @installation.pending_credit_check?
      @responder.cant_schedule_while_credit_check_pending
      return
    end

    if schedule!
      if @installation.scheduled_date
        @responder.scheduling_succeeded
      end
      @responder.do_post_success_cleanup
    else
      @responder.scheduling_failed
    end
  rescue Exception => e
    @responder.handle_exception e
  end

  private

  def schedule!
    @installation.schedule!(@desired_date, :installation_type => @installation_type, :city => @city)
  end
end

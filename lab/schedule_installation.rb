class ScheduleInstallation
  def initialize(controller, installation, city)
    responder_class = controller.request.xhr? ? AJAXResponder : HTMLResponder
    @responder = responder_class.new(controller, installation)
    @installation = installation
    @city = city
  end

  def method_missing(m, *a, &b)
    @responder.send(m, *a, &b)
  end

  def call
    if @installation.pending_credit_check?
      @responder.cant_schedule_while_credit_check_pending
      return
    end

    begin
      audit_trail_for(current_user) do
        if schedule!
          if @installation.scheduled_date
            @responder.scheduling_succeeded
          end
          @responder.do_post_success_cleanup
        else
          @responder.scheduling_failed
        end
      end
    rescue Exception => e
      @responder.handle_exception e
    end
  end

  private

  def schedule!
    @installation.schedule!(params[:desired_date], :installation_type => params[:installation_type], :city => @city)
  end
end

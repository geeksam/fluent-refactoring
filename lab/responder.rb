class Responder
  def initialize(controller, installation)
    @controller = controller
    @installation = installation
  end

  def method_missing(m, *a, &b)
    @controller.send(m, *a, &b)
  end
end

class AJAXResponder < Responder
  def cant_schedule_while_credit_check_pending
    render :json => {:errors => ["Cannot schedule installation while credit check is pending"]}, :status => 400
  end

  def handle_exception(e)
    begin
      raise e
    rescue ActiveRecord::RecordInvalid => e
      render :json => {:errors => [e.message] }
    rescue ArgumentError => e
      render :json => {:errors => ["Could not schedule installation. Start by making sure the desired date is on a business day."]}
    end
  end

  def scheduling_failed
    render :json => {:errors => [%Q{Could not update installation. #{@installation.errors.full_messages.join(' ')}}] }
  end

  def scheduling_succeeded
    date = @installation.scheduled_date.in_time_zone(@installation.city.timezone).to_date
    render :json => {:errors => nil, :html => schedule_response(@installation, date)}
  end

  def do_post_success_cleanup
    # do nothing
  end
end

class HTMLResponder < Responder
  def cant_schedule_while_credit_check_pending
    flash[:error] = "Cannot schedule installation while credit check is pending"
    redirect_to installations_path(:city_id => @installation.city_id, :view => "calendar")
  end

  def handle_exception(e)
    flash[:error] = e.message
    redirect_to(@installation.customer_provided_equipment? ? customer_provided_installations_path : installations_path(:city_id => @installation.city_id, :view => "calendar"))
  end

  def scheduling_failed
    flash[:error] = %Q{Could not schedule installation, check the phase of the moon}
    redirect_to(@installation.customer_provided_equipment? ? customer_provided_installations_path : installations_path(:city_id => @installation.city_id, :view => "calendar"))
  end

  def scheduling_succeeded
    if @installation.customer_provided_equipment?
      flash[:success] = %Q{Installation scheduled}
    else
      flash[:success] = %Q{Installation scheduled! Don't forget to order the equipment also.}
    end
  end

  def do_post_success_cleanup
    redirect_to(@installation.customer_provided_equipment? ? customer_provided_installations_path : installations_path(:city_id => @installation.city_id, :view => "calendar"))
  end
end

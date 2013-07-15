class ScheduleInstallation
  def initialize(controller, installation, city)
    @controller = controller
    @installation = installation
    @city = city
  end

  def method_missing(m, *a, &b)
    @controller.send(m, *a, &b)
  end

  def call
    desired_date = params[:desired_date]
    if @installation.pending_credit_check?
      cant_schedule_while_credit_check_pending
      return
    end

    begin
      if request.xhr?
        audit_trail_for(current_user) do
          if @installation.schedule!(desired_date, :installation_type => params[:installation_type], :city => @city)
            if @installation.scheduled_date
              date = @installation.scheduled_date.in_time_zone(@installation.city.timezone).to_date
              render :json => {:errors => nil, :html => schedule_response(@installation, date)}
            end
          else
            render :json => {:errors => [%Q{Could not update installation. #{@installation.errors.full_messages.join(' ')}}] }
          end
        end
      else
        audit_trail_for(current_user) do
          if @installation.schedule!(desired_date, :installation_type => params[:installation_type], :city => @city)
            if @installation.scheduled_date
              if @installation.customer_provided_equipment?
                flash[:success] = %Q{Installation scheduled}
              else
                flash[:success] = %Q{Installation scheduled! Don't forget to order the equipment also.}
              end
            end
          else
            flash[:error] = %Q{Could not schedule installation, check the phase of the moon}
          end
        end
        redirect_to(@installation.customer_provided_equipment? ? customer_provided_installations_path : installations_path(:city_id => @installation.city_id, :view => "calendar"))
      end
    rescue Exception => e
      handle_exception e
    end
  end

  private

  def cant_schedule_while_credit_check_pending
    if request.xhr?
      render :json => {:errors => ["Cannot schedule installation while credit check is pending"]}, :status => 400
    else
      flash[:error] = "Cannot schedule installation while credit check is pending"
      redirect_to installations_path(:city_id => @installation.city_id, :view => "calendar")
    end
  end

  def handle_exception(e)
    if request.xhr?
      begin
        raise e
      rescue ActiveRecord::RecordInvalid => e
        render :json => {:errors => [e.message] }
      rescue ArgumentError => e
        render :json => {:errors => ["Could not schedule installation. Start by making sure the desired date is on a business day."]}
      end
    else
      flash[:error] = e.message
      redirect_to(@installation.customer_provided_equipment? ? customer_provided_installations_path : installations_path(:city_id => @installation.city_id, :view => "calendar"))
    end
  end
end

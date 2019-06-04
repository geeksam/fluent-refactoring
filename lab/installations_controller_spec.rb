require 'active_support'
require 'date'

# stub out dependencies
module ActionController
  class Base; end
end
module ActiveRecord
  class Base; end
  class RecordInvalid < Exception; end
end

require File.join(File.dirname(__FILE__), 'installations_controller')


describe InstallationsController do
  let(:controller) { subject }
  before :each do
    subject.instance_variable_set('@city', city)
    def subject.audit_trail_for(*_); yield; end
  end

  def invoke!
    subject.schedule
  end

  context "when the request is .xhr?," do
    before(:each) do
      request.should_receive(:xhr?).at_least(:once).and_return(true)
    end

    context "when the installation is .pending_credit_check?," do
      before(:each) do
        installation.should_receive(:pending_credit_check?).at_least(:once).and_return(true)
      end

      it "renders failure JSON with a 400" do
        expect_render( {:status => 400, :json => {:errors => ["Cannot schedule installation while credit check is pending"]}} )
        invoke!
      end
    end

    context "when the installation is not .pending_credit_check?," do
      before(:each) do
        installation.should_receive(:pending_credit_check?).at_least(:once).and_return(false)
        controller.should_receive(:audit_trail_for).and_yield
      end

      context "and the installation can be scheduled," do
        before(:each) do
          installation.should_receive(:schedule!) \
            .with(*expected_schedule_args)
            .at_least(:once)
            .and_return(true)
        end

        context "and the installation's scheduled_date is truthy," do
          before(:each) do
            installation.should_receive(:scheduled_date).at_least(:once).and_return(scheduled_date)
          end

          it "renders success JSON" do
            scheduled_date.should_receive(:in_time_zone).with(city.timezone).at_least(:once).and_return(scheduled_date)
            subject.should_receive(:schedule_response) \
              .with(installation, scheduled_date) \
              .at_least(:once) \
              .and_return(:schedule_response)
            expect_render( { :json => { :errors => nil, :html => :schedule_response } } )
            invoke!
          end
        end

        context "and the installation's scheduled_date is falsy," do
          before(:each) do
            installation.should_receive(:scheduled_date).at_least(:once).and_return(nil)
          end

          it "falls through to default behavior" do
            # no expectations; just invoke the method
            invoke!
          end
        end
      end

      context "and the installation cannot be scheduled," do
        before(:each) do
          installation.should_receive(:schedule!) \
            .with(*expected_schedule_args)
            .at_least(:once)
            .and_return(false)
        end

        it "renders failure JSON" do
          errors = stub(:full_messages => %w[foo bar])
          installation.should_receive(:errors).at_least(:once).and_return(errors)
          expect_render( { :json => { :errors => ["Could not update installation. foo bar"] } } )
          invoke!
        end
      end

      context "and scheduling the installation raises ActiveRecord::RecordInvalid," do
        before(:each) do
          installation.should_receive(:schedule!).and_raise(ActiveRecord::RecordInvalid.new("O NOES!"))
        end

        it "renders failure JSON" do
          expect_render( { :json => { :errors => ["O NOES!"] } } )
          invoke!
        end
      end

      context "and scheduling the installation raises ArgumentError," do
        before(:each) do
          installation.should_receive(:schedule!).and_raise(ArgumentError.new("You fell victim to one of the classic blunders!!"))
        end

        it "renders failure JSON" do
          expect_render( { :json => { :errors => ["Could not schedule installation. Start by making sure the desired date is on a business day."] } } )
          invoke!
        end
      end

      context "and scheduling the installation raises some other exception," do
        before(:each) do
          installation.should_receive(:schedule!).and_raise(Exception.new("U SUCK!"))
        end

        it "asplodes" do
          expect { invoke! }.to raise_error(Exception)
        end
      end
    end
  end

  context "when the request is not .xhr?," do
    before(:each) do
      request.should_receive(:xhr?).at_least(:once).and_return(false)
    end

    context "and the installation is .pending_credit_check?" do
      before(:each) do
        installation.should_receive(:pending_credit_check?).at_least(:once).and_return(true)
      end

      it "sets flash error and redirects to installations_path" do
        expect_flash :error, "Cannot schedule installation while credit check is pending"
        controller.should_receive(:installations_path).with({ :city_id => installation.city_id, :view => 'calendar' }).at_least(:once).and_return(:installations_path)
        expect_redirect(:installations_path) \
          .and_return(true) # NOTE: this line is necessitated by that "and return". Funny!
        invoke!
      end
    end

    context "and the installation is not .pending_credit_check?" do
      before(:each) do
        installation.should_receive(:pending_credit_check?).at_least(:once).and_return(false)
        controller.should_receive(:audit_trail_for).and_yield
      end

      context "and the installation can be scheduled," do
        before(:each) do
          installation.should_receive(:schedule!).at_least(:once).and_return(true)
        end

        context "and the installation's scheduled_date is truthy," do
          before(:each) do
            installation.should_receive(:scheduled_date).at_least(:once).and_return(scheduled_date)
          end

          context "and the installation is #customer_provided_equipment?," do
            before(:each) do
              installation.should_receive(:customer_provided_equipment?).at_least(:once).and_return(true)
            end

            it "sets flash success and redirects to customer_provided_installations_path " do
              expect_flash :success, "Installation scheduled"
              expect_redirect(:customer_provided_installations_path)
              invoke!
            end
          end

          context "and the installation is not #customer_provided_equipment?," do
            before(:each) do
              installation.should_receive(:customer_provided_equipment?).at_least(:once).and_return(false)
            end

            it "sets flash success and redirects to installations path" do
              expect_flash :success, "Installation scheduled! Don't forget to order the equipment also."
              controller.should_receive(:installations_path).with({ :city_id => installation.city_id, :view => 'calendar' }).at_least(:once).and_return(:installations_path)
              expect_redirect(:installations_path)
              invoke!
            end
          end
        end

        context "and the installation's scheduled_date is falsy," do
          before(:each) do
            installation.should_receive(:scheduled_date).at_least(:once).and_return(nil)
          end

          context "and the installation is #customer_provided_equipment?," do
            before(:each) do
              installation.should_receive(:customer_provided_equipment?).at_least(:once).and_return(true)
            end

            it "just redirects to customer_provided_installations_path" do
              expect_redirect(:customer_provided_installations_path)
              invoke!
            end
          end

          context "and the installation is not #customer_provided_equipment?," do
            before(:each) do
              installation.should_receive(:customer_provided_equipment?).at_least(:once).and_return(false)
            end

            it "just redirects to installations_path" do
              controller.should_receive(:installations_path).with({ :city_id => installation.city_id, :view => 'calendar' }).at_least(:once).and_return(:installations_path)
              expect_redirect(:installations_path)
              invoke!
            end
          end
        end
      end

      context "and the installation cannot be scheduled," do
        before(:each) do
          installation.should_receive(:schedule!).at_least(:once).and_return(false)
        end

        context "and the installation is #customer_provided_equipment?," do
          before(:each) do
            installation.should_receive(:customer_provided_equipment?).at_least(:once).and_return(true)
          end

          it "sets flash error and redirects to customer_provided_installations_path" do
            expect_flash :error, "Could not schedule installation, check the phase of the moon"
            expect_redirect :customer_provided_installations_path
            invoke!
          end
        end

        context "and the installation is not #customer_provided_equipment?," do
          before(:each) do
            installation.should_receive(:customer_provided_equipment?).at_least(:once).and_return(false)
          end

          it "sets flash error and redirects to installations_path" do
            expect_flash :error, "Could not schedule installation, check the phase of the moon"
            controller.should_receive(:installations_path).with({ :city_id => installation.city_id, :view => 'calendar' }).at_least(:once).and_return(:installations_path)
            expect_redirect :installations_path
            invoke!
          end
        end
      end

    #!@# continue here

      context "and scheduling the installation raises any exception" do
        before(:each) do
          installation.should_receive(:schedule!).and_raise(ArgumentError.new("What I wouldn't give for a Holocaust Cloak."))
        end

        context "and the installation is #customer_provided_equipment?," do
          before(:each) do
            installation.should_receive(:customer_provided_equipment?).at_least(:once).and_return(true)
          end

          it "sets flash error and redirects to customer_provided_installations_path" do
            expect_flash :error, "What I wouldn't give for a Holocaust Cloak."
            expect_redirect :customer_provided_installations_path
            invoke!
          end
        end

        context "and the installation is not #customer_provided_equipment?," do
          before(:each) do
            installation.should_receive(:customer_provided_equipment?).at_least(:once).and_return(false)
          end

          it "sets flash error and redirects to installations_path" do
            expect_flash :error, "What I wouldn't give for a Holocaust Cloak."
            controller.should_receive(:installations_path).with({ :city_id => installation.city_id, :view => 'calendar' }).at_least(:once).and_return(:installations_path)
            expect_redirect :installations_path
            invoke!
          end
        end
      end
    end
  end


  # Infrastructure

  before :each do
    controller.stub!({
      :params => params,
      :flash => flash,
      :request => request,
      :current_user => :current_user,
      :customer_provided_installations_path => :customer_provided_installations_path,
    })
    controller.instance_variable_set(:@installation, installation)
  end
  let(:params) { {
    :desired_date => 'tuesday',
    :installation_type => 'residential',
  } }
  let(:flash) { stub('flash') }
  let(:request) { stub('request') }

  let(:installation) { stub('installation', :city => city, :city_id => 42) }
  let(:city) { stub('city').as_null_object }
  let(:scheduled_date) { (Date.today + 5) }

  # >.<  these are the expected args for the installation#schedule! method
  let(:expected_schedule_args) { [
    params[:desired_date],
    {
      :installation_type => params[:installation_type],
      :city => city,
    }
  ] }

  def expect_render(*args)
    controller.should_receive(:render).with(*args)
  end
  def expect_redirect(*args)
    controller.should_receive(:redirect_to).with(*args)
  end
  def expect_flash(key, value)
    flash.should_receive(:[]=).with(key, value)
  end
end

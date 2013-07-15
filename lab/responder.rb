class Responder
  def initialize(controller, installation)
    @controller = controller
    @installation = installation
  end

  def method_missing(m, *a, &b)
    @controller.send(m, *a, &b)
  end
end

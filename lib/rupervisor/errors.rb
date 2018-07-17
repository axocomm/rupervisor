module Rupervisor
  class RuperfileError < StandardError
  end

  class ScenarioUndefined < RuperfileError
  end

  class ActionUndefined < RuperfileError
  end
end

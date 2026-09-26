class ImportJob < ApplicationJob
  def perform(import)
    import.process
  end
end

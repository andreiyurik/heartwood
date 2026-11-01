class ArchiveJob < ApplicationJob
  def perform(archive)
    archive.build
  end
end

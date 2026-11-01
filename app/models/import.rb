class Import < ApplicationRecord
  include Archived

  belongs_to :tree
  belongs_to :user
  has_one_attached :file

  enum :status, %w[pending processing completed failed].index_by(&:itself), default: "pending"

  validate :file_is_gedcom

  broadcasts_refreshes

  def process
    processing!

    read_file do |source, media|
      records = Gedcom::Parser.new(source).parse
      return failed_with("no_records") if records[:records].none?

      result = LiveUpdates.suppressing { Gedcom::Mapper.new(records[:records], tree: tree, media: media).import! }
      broadcast_refresh_later_to tree
      update!(status: "completed", people_count: result[:people].size, families_count: result[:families].size,
              warnings: records[:warnings] + result[:warnings])
    end
  rescue ActiveRecord::RecordInvalid => error
    failed_with(error.record.errors.of_kind?(:base, :tree_full) ? "tree_full" : "invalid")
  rescue Zip::Error
    failed_with("no_records")
  end

  private
    def read_file(&block)
      archive? ? read_archive(&block) : yield(file.download, nil)
    end

    def failed_with(error)
      update!(status: "failed", error: error)
    end

    def file_is_gedcom
      if !file.attached?
        errors.add(:file, :blank)
      elsif !file.filename.extension_without_delimiter.downcase.in?(%w[ged zip gdz])
        errors.add(:file, :invalid)
      end
    end
end

class Import < ApplicationRecord
  belongs_to :tree
  belongs_to :user
  has_one_attached :file

  enum :status, %w[pending processing completed failed].index_by(&:itself), default: "pending"

  validate :file_is_gedcom

  broadcasts_refreshes

  def process
    processing!
    records = Gedcom::Parser.new(file.download).parse
    return failed_with("no_records") if records[:records].none?

    result = LiveUpdates.suppressing { Gedcom::Mapper.new(records[:records], tree: tree).import! }
    broadcast_refresh_later_to tree
    update!(status: "completed", people_count: result[:people].size, families_count: result[:families].size,
            warnings: records[:warnings] + result[:warnings])
  rescue ActiveRecord::RecordInvalid => error
    failed_with(error.record.errors.of_kind?(:base, :tree_full) ? "tree_full" : "invalid")
  end

  private
    def failed_with(error)
      update!(status: "failed", error: error)
    end

    def file_is_gedcom
      if !file.attached?
        errors.add(:file, :blank)
      elsif !file.filename.to_s.downcase.end_with?(".ged")
        errors.add(:file, :invalid)
      end
    end
end

class DigestMailerPreview < ActionMailer::Preview
  def weekly
    DigestMailer.weekly(TreeMembership.first, since: 1.year.ago)
  end
end

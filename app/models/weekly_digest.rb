# The weekly letter to one member about one tree: what the others did since last week. See [[digest]].
class WeeklyDigest
  WINDOW = 1.week
  NAMED_PEOPLE = 10

  def self.deliver_all(since: WINDOW.ago)
    TreeMembership.joins(:user).where(users: { weekly_digest: true }).includes(:user, :tree).find_each do |membership|
      DigestMailer.weekly(membership, since: since).deliver_later if new(membership, since: since).news?
    end
  end

  attr_reader :membership, :since
  delegate :tree, :user, to: :membership

  def initialize(membership, since: WINDOW.ago)
    @membership, @since = membership, since
  end

  def news? = edits.exists? || comments.exists? || answers.exists?

  def added_people
    tree.people.where(id: edits.added.where(subject_type: "Person").select(:subject_id)).order(:created_at)
  end

  def changes_count = edits.count - edits.added.where(subject_type: %w[ Person Photo ]).count

  def photos_count = edits.added.where(subject_type: "Photo").count

  def comments_count = comments.count

  def answers_count = answers.count

  def contributors
    User.where(id: edits.select(:user_id)).or(User.where(id: comments.select(:user_id))).order(:name).pluck(:name)
  end

  def open_questions = tree.questions.open.latest.limit(5).to_a

  private
    def edits = tree.edits.where(created_at: since..).where.not(user_id: user.id)

    def comments = tree.comments.where(created_at: since..).where.not(user_id: user.id)

    def answers
      recent = Answer.joins(:question).where(questions: { tree_id: tree.id }, created_at: since..)
      recent.where(user_id: nil).or(recent.where.not(user_id: user.id))
    end
end

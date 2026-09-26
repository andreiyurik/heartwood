# up: generations from the focus person to the common ancestor; down: the same for the other person;
# sex: the other person's, so we say "mother", not "parent".
class Kinship
  def self.spouse(sex)
    I18n.t("relationships.spouse.#{normalize_sex(sex)}")
  end

  def self.normalize_sex(sex) = %w[M F].include?(sex) ? sex : "U"

  def initialize(up:, down:, sex:)
    @up   = up
    @down = down
    @sex  = self.class.normalize_sex(sex)
  end

  def to_s
    label
  end

  private

  attr_reader :up, :down, :sex

  def label
    return term("parent")               if ancestor? && up == 1
    return greats(up - 2, "grandparent") if ancestor?
    return term("child")                if descendant? && down == 1
    return greats(down - 2, "grandchild") if descendant?
    return term("sibling")              if up == 1 && down == 1
    return greats(up - 2, "aunt_uncle") if down == 1
    return greats(down - 2, "niece_nephew") if up == 1
    cousin
  end

  def ancestor?   = down.zero?
  def descendant? = up.zero?

  def greats(count, key)
    I18n.t("relationships.great_prefix") * count + term(key)
  end

  def term(key) = I18n.t("relationships.#{key}.#{sex}")

  def cousin
    degree  = [ up, down ].min - 1
    removed = (up - down).abs
    base    = I18n.t("relationships.cousin", ordinal: ordinal(degree))
    removed.zero? ? base : "#{base} #{removal(removed)}"
  end

  def ordinal(n)
    I18n.t("relationships.ordinals").fetch(n - 1) do
      I18n.t("relationships.ordinal_fallback", count: n)
    end
  end

  def removal(n)
    case n
    when 1 then I18n.t("relationships.removed.once")
    when 2 then I18n.t("relationships.removed.twice")
    else        I18n.t("relationships.removed.other", count: n)
    end
  end
end

# The small coat of arms next to a tree's name: chosen parts, or an uploaded picture.
module Tree::Crest
  extend ActiveSupport::Concern

  SHAPES = {
    "shield" => "M32 4 56 10v20c0 16-10 26-24 31C18 56 8 46 8 30V10z",
    "round"  => "M32 4a28 28 0 1 0 0 56 28 28 0 0 0 0-56z",
    "banner" => "M11 5h42v43L32 60 11 48z",
    "arch"   => "M10 60V26a22 22 0 0 1 44 0v34z"
  }.freeze

  HUES = { "forest" => 138, "olive" => 105, "ochre" => 70, "brick" => 35, "wine" => 10, "plum" => 330, "navy" => 260, "teal" => 200 }.freeze

  LINE = %(fill="none" stroke="currentColor" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round").freeze

  # Drawn for this project in a 64×64 box around (32, 30); they inherit the crest's ink through currentColor.
  SYMBOLS = {
    "tree"      => %(<path #{LINE} d="M32 47V25M32 38l-8-8M32 34l8-7"/><g fill="currentColor"><circle cx="32" cy="20" r="5"/><circle cx="22.5" cy="28" r="4.5"/><circle cx="41.5" cy="25" r="4.5"/></g>),
    "star"      => %(<path fill="currentColor" d="M32 15l4.4 9.6 10.4 1.2-7.7 7.2 2.1 10.300L32 38.200l-9.2 5.1 2.1-10.3-7.7-7.2 10.4-1.200z"/>),
    "sun"       => %(<circle fill="currentColor" cx="32" cy="30" r="6.5"/><path #{LINE} d="M32 15v4M32 41v4M17 30h4M43 30h4M21.4 19.400l2.8 2.800M39.8 37.800l2.8 2.800M42.6 19.400l-2.8 2.800M24.2 37.800l-2.8 2.8"/>),
    "heart"     => %(<path fill="currentColor" d="M32 44c-8-5.6-13-10-13-15.600a6.8 6.8 0 0 1 13-2.8 6.8 6.8 0 0 1 13 2.800C45 34 40 38.4 32 44z"/>),
    "house"     => %(<path fill="currentColor" d="M32 16 17 29h4v14h8v-8h6v8h8V29h4z"/>),
    "anchor"    => %(<circle #{LINE} cx="32" cy="19" r="3"/><path #{LINE} d="M32 22v22M26 28h12M20 36c1 5 5.5 8 12 8s11-3 12-8"/>),
    "key"       => %(<circle #{LINE} cx="32" cy="21" r="5"/><path #{LINE} d="M32 26v19M32 38h5M32 44h5"/>),
    "crown"     => %(<path fill="currentColor" d="M19 41 17 23l8 7 7-11 7 11 8-7-2 18z"/>),
    "book"      => %(<path fill="currentColor" d="M31 23c-4-3-9-3.5-13-2.500v19c4-1 9-.5 13 2.500zM33 23c4-3 9-3.5 13-2.500v19c-4-1-9-.5-13 2.500z"/>),
    "mountain"  => %(<path fill="currentColor" d="M15 42 27 20l6 10 4-6 12 18z"/>),
    "flower"    => %(<g fill="currentColor"><circle cx="32" cy="20" r="5"/><circle cx="40.6" cy="26.2" r="5"/><circle cx="37.3" cy="36.3" r="5"/><circle cx="26.7" cy="36.3" r="5"/><circle cx="23.4" cy="26.2" r="5"/></g>),
    "wheat"     => %(<path #{LINE} d="M32 46V22"/><g fill="currentColor"><ellipse cx="32" cy="18" rx="3" ry="5"/><ellipse cx="26.5" cy="25" rx="3" ry="5" transform="rotate(-35 26.5 25)"/><ellipse cx="37.5" cy="25" rx="3" ry="5" transform="rotate(35 37.5 25)"/><ellipse cx="26.5" cy="33" rx="3" ry="5" transform="rotate(-35 26.5 33)"/><ellipse cx="37.5" cy="33" rx="3" ry="5" transform="rotate(35 37.5 33)"/></g>),
    "bell"      => %(<path fill="currentColor" d="M32 15c-6 0-9.5 5-9.5 11v7L19 39h26l-3.5-6v-7c0-6-3.5-11-9.5-11z"/><circle fill="currentColor" cx="32" cy="43" r="2.8"/>),
    "horseshoe" => %(<path fill="none" stroke="currentColor" stroke-width="6" stroke-linecap="round" d="M23 43V29a9 9 0 0 1 18 0v14"/>)
  }.freeze

  IMAGE_CONTENT_TYPES = %w[image/png image/jpeg].freeze
  IMAGE_MAX_BYTES     = 5.megabytes

  # "Род Пушкиных" is the Pushkins' tree: the initial that matters is П.
  LEADING_WORDS = /\A(род|семья|древо|family|the)\s+/i

  included do
    has_one_attached :crest_image

    normalizes :crest_shape, :crest_symbol, with: ->(value) { value.presence }

    validates :crest_shape,  inclusion: { in: SHAPES.keys },  allow_nil: true
    validates :crest_symbol, inclusion: { in: SYMBOLS.keys }, allow_nil: true
    validates :crest_hue,    inclusion: { in: 0..359 },       allow_nil: true
    validate  :crest_image_is_a_picture, if: -> { crest_image.attached? }
  end

  def crest_shape_name = crest_shape || SHAPES.keys.first
  def crest_shape_path = SHAPES.fetch(crest_shape_name)
  def crest_hue_value  = crest_hue || Zlib.crc32(name.to_s) % 360
  def crest_symbol_svg = SYMBOLS[crest_symbol]
  def crest_letter     = name.to_s.sub(LEADING_WORDS, "").first.to_s.upcase

  private
    def crest_image_is_a_picture
      errors.add(:crest_image, :invalid_content_type) unless crest_image.content_type.in?(IMAGE_CONTENT_TYPES)
      errors.add(:crest_image, :too_large) if crest_image.byte_size > IMAGE_MAX_BYTES
    end
end

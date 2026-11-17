require "vips"

# The 1200×630 picture a messenger shows for an invitation or a view-only link.
class Tree::Card
  PAPER = "#fcf5e9"
  INK   = "#12202b"
  MUTED = "#5e6b75"
  TONE  = [ 0.56, 0.09 ].freeze

  def initialize(tree)
    @tree = tree
  end

  # The crest alone, for a browser tab.
  def icon_svg
    %(<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">#{crest}</svg>)
  end

  def png
    card = draw
    card = card.composite2(uploaded_crest, :over, x: 440, y: 70) if @tree.crest_image.attached?
    card.write_to_buffer(".png")
  end

  private
    # Active Storage blocks libvips' untrusted loaders, SVG among them. This SVG is ours — the only
    # outside text in it is the escaped tree name — so the in-memory loader alone is let through.
    def draw
      Vips.block("VipsForeignLoadSvgBuffer", false)
      Vips::Image.svgload_buffer(svg)
    end

    # The uploaded picture never passes through the SVG renderer: libvips decodes it and lays it over the card.
    def uploaded_crest
      Vips::Image.thumbnail_buffer(@tree.crest_image.download, 320, height: 320, crop: :centre).colourspace(:srgb)
    end

    def svg
      <<~SVG
        <svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630" viewBox="0 0 1200 630">
          <rect width="1200" height="630" fill="#{PAPER}"/>
          <g transform="translate(440 70) scale(5)">#{crest}</g>
          <text x="600" y="500" text-anchor="middle" font-family="DejaVu Sans, sans-serif" font-weight="bold" font-size="60" fill="#{INK}">#{escape(@tree.name.truncate(30))}</text>
          <text x="600" y="560" text-anchor="middle" font-family="DejaVu Sans, sans-serif" font-size="30" fill="#{MUTED}">#{escape(I18n.t("landing.footer.tagline").truncate(60))}</text>
        </svg>
      SVG
    end

    def crest
      return if @tree.crest_image.attached?

      mark = @tree.crest_symbol_svg ||
        %(<text x="32" y="43" text-anchor="middle" font-family="DejaVu Sans, sans-serif" font-weight="bold" font-size="30" fill="currentColor">#{escape(@tree.crest_letter)}</text>)
      %(<path d="#{@tree.crest_shape_path}" fill="#{self.class.hex(@tree.crest_hue_value)}"/><g color="#{PAPER}">#{mark}</g>)
    end

    def escape(text) = ERB::Util.html_escape(text)

    # librsvg knows no oklch(), so the avatar tone is converted to sRGB here (Björn Ottosson's OKLab matrices).
    def self.hex(hue)
      lightness, chroma = TONE
      a = chroma * Math.cos(hue * Math::PI / 180)
      b = chroma * Math.sin(hue * Math::PI / 180)

      l = (lightness + 0.3963377774 * a + 0.2158037573 * b)**3
      m = (lightness - 0.1055613458 * a - 0.0638541728 * b)**3
      s = (lightness - 0.0894841775 * a - 1.2914855480 * b)**3

      linear = [ 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
                -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
                -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s ]

      "#%02x%02x%02x" % linear.map { |channel|
        value = channel <= 0.0031308 ? 12.92 * channel : 1.055 * (channel**(1 / 2.4)) - 0.055
        (value.clamp(0, 1) * 255).round
      }
    end
end

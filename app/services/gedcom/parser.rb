module Gedcom
  class Parser
    # Regex for a single GEDCOM line: LEVEL [XREF] TAG [VALUE]
    LINE_RE = /\A(\d+)\s+(@[^@]+@)?\s*([A-Z0-9_]+)(?:\s+(.*))?\z/

    def initialize(source)
      @source   = source.dup.force_encoding("UTF-8")
      @warnings = []
    end

    # Parse a single GEDCOM line string into a hash, or nil for blank lines.
    # This is a class method for quick one-off use; instance parse builds the tree.
    def self.parse_line(line)
      line = line.strip
      return nil if line.empty?

      m = LINE_RE.match(line)
      return nil unless m

      { level: m[1].to_i, xref: m[2], tag: m[3], value: m[4]&.strip.presence }
    end

    # Parse the full source into a record tree.
    # Returns { records: [...], warnings: [...] }
    # Each record: { level:, xref:, tag:, value:, children: [...] }
    def parse
      stripped = @source.delete_prefix("\xEF\xBB\xBF")
      lines    = stripped.lines.map(&:strip)

      raw = []
      lines.each_with_index do |line, idx|
        next if line.empty?

        parsed = self.class.parse_line(line)
        if parsed.nil?
          @warnings << "Line #{idx + 1}: unparseable — #{line.inspect}"
        else
          parsed[:children] = []
          raw << parsed
        end
      end

      records = build_tree(raw)
      { records: records, warnings: @warnings }
    end

    private

    def build_tree(flat)
      # Only level-0 lines are top-level records; strip HEAD/TRLR from output
      # but still parse them so children are attached.
      stack   = []
      roots   = []

      flat.each do |node|
        node = node.dup
        node[:children] = []

        if node[:level] == 0
          roots << node
          stack  = [ node ]
        else
          # Pop back to the parent whose level is one less than ours.
          stack.pop while stack.size > 1 && stack.last[:level] >= node[:level]
          stack.last[:children] << node
          stack << node
        end
      end

      # Exclude the structural HEAD and TRLR from the main records list.
      roots.reject { |r| %w[HEAD TRLR].include?(r[:tag]) }
    end
  end
end

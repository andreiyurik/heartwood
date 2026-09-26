module Gedcom
  class Parser
    LINE_RE = /\A(\d+)\s+(@[^@]+@)?\s*([A-Z0-9_]+)(?:\s+(.*))?\z/

    def initialize(source)
      @source   = source.dup.force_encoding("UTF-8")
      @warnings = []
    end

    def self.parse_line(line)
      line = line.strip
      return nil if line.empty?

      m = LINE_RE.match(line)
      return nil unless m

      { level: m[1].to_i, xref: m[2], tag: m[3], value: m[4]&.strip.presence }
    end

    def parse
      stripped = @source.delete_prefix("\xEF\xBB\xBF")
      lines    = stripped.lines.map(&:strip)

      raw = []
      lines.each_with_index do |line, idx|
        next if line.empty?

        parsed = Parser.parse_line(line)
        if parsed.nil?
          @warnings << "Line #{idx + 1}: unparseable — #{line.inspect}"
        else
          raw << parsed
        end
      end

      records = build_tree(raw)
      { records: records, warnings: @warnings }
    end

    private

    def build_tree(flat)
      stack   = []
      roots   = []

      flat.each do |node|
        node = node.dup
        node[:children] = []

        if node[:level] == 0
          roots << node
          stack  = [ node ]
        else
          stack.pop while stack.size > 1 && stack.last[:level] >= node[:level]
          stack.last[:children] << node
          stack << node
        end
      end

      roots.reject { |r| %w[HEAD TRLR].include?(r[:tag]) }
    end
  end
end

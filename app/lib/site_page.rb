# frozen_string_literal: true

# The site's other pages, content/pages/*.yml, read into Data objects: the
# Workflow, Background and Contact copy (design doc, section 2).
#
#   SitePage.fetch(:contact).links.first.label   # => "GitHub"
#
# A page is a title, a description (its meta description), an intro, links and
# sections. A section is a heading over paragraphs and groups of key and value
# rows, the same groups a step's body shows. Portfolio builds its projects from
# the same sections and links, so both read and check them here.
#
# Every word comes from the file (docs/rules/content-is-files.md); copy not yet
# written stays in [brackets] (docs/rules/no-invented-content.md). Loading
# validates, so a broken edit fails at the first read and in content:schema.
module SitePage
  ROOT = Rails.root.join("content/pages")
  # The pages a route reads. Each must exist: content:schema fails without
  # one, rather than leave its route to raise on the live site.
  ROUTED = %w[work workflow background contact].freeze

  REQUIRED = %w[title description intro].freeze
  OPTIONAL = %w[links sections].freeze
  SECTION_KEYS = %w[heading paragraphs groups].freeze
  # Where a link may go. A link still to be written is a [placeholder] and
  # renders as text, not as a link to nowhere.
  URL = %r{\A(https://|mailto:)\S+\z}

  Invalid = Class.new(StandardError)

  Page = Data.define(:key, :title, :description, :intro, :links, :sections)
  Section = Data.define(:heading, :paragraphs, :groups)
  # Named as DeliveryThread names them, so DetailGroupComponent draws either.
  Group = Data.define(:title, :rows)
  Row = Data.define(:key, :value)
  Link = Data.define(:label, :url) do
    def placeholder? = !url.match?(URL)
  end

  class << self
    # @raise [KeyError] when no content/pages/<key>.yml exists
    # @raise [Invalid] when the file breaks the schema
    # The key is matched against the files that exist, never joined into a
    # path. Outside development a page is read once.
    def fetch(key)
      return cache[key.to_s] if cache.key?(key.to_s) && !Rails.env.development?

      path = ROOT.glob("*.yml").find { |file| file.basename(".yml").to_s == key.to_s }
      raise KeyError, "no page #{key} in #{ROOT}" unless path
      return load(path) if Rails.env.development?

      cache[key.to_s] = load(path)
    end

    def all = ROOT.glob("*.yml").sort.map { |path| fetch(path.basename(".yml")) }

    # @raise [Invalid] naming the file and every problem found
    def load(path)
      data = YAML.safe_load_file(path, freeze: true)
      errors = page_errors(data)
      raise Invalid, errors.map { |error| "#{File.basename(path)}: #{error}" }.join("\n") if errors.any?

      Page.new(key: File.basename(path, ".yml"), title: data["title"], description: data["description"],
        intro: data["intro"], links: links(data["links"]), sections: sections(data["sections"]))
    end

    def links(list) = Array(list).map { |link| Link.new(label: link["label"], url: link["url"]) }.freeze

    def sections(list)
      Array(list).map do |section|
        Section.new(heading: section["heading"], paragraphs: Array(section["paragraphs"]).freeze, groups: groups(section["groups"]))
      end.freeze
    end

    def groups(list)
      Array(list).map do |group|
        Group.new(title: group["title"], rows: group["rows"].map { |row| Row.new(key: row["k"], value: row["v"]) }.freeze)
      end.freeze
    end

    # Every problem in one pass, so a broken file is fixed in one edit.
    def page_errors(data)
      return [ "top level must be a mapping with #{REQUIRED.join(', ')}" ] unless data.is_a?(Hash)

      REQUIRED.select { |key| missing?(data[key]) }.map { |key| "missing #{key}" } +
        (data.keys - REQUIRED - OPTIONAL).map { |key| "unknown key #{key}" } +
        link_errors(data["links"]) + section_errors(data["sections"])
    end

    def link_errors(links, where: "links")
      return [] if links.nil?
      return [ "#{where} must be a list" ] unless links.is_a?(Array)

      links.each_with_index.flat_map do |link, index|
        name = "#{where}[#{index + 1}]"
        next [ "#{name} needs a label and a url" ] unless pair?(link, "label", "url")

        errors = (link.keys - %w[label url]).map { |key| "#{name}: unknown key #{key}" }
        url = link["url"].to_s
        errors << "#{name}: url must start https:// or mailto:, or be a [placeholder]" unless url.match?(URL) || url.match?(/\A\[[^\]]+\]\z/)
        errors
      end
    end

    def section_errors(sections, where: "sections")
      return [] if sections.nil?
      return [ "#{where} must be a list" ] unless sections.is_a?(Array)

      sections.each_with_index.flat_map do |section, index|
        name = "#{where}[#{index + 1}]"
        next [ "#{name} must be a mapping with a heading" ] unless section.is_a?(Hash)

        errors = (section.keys - SECTION_KEYS).map { |key| "#{name}: unknown key #{key}" }
        errors << "#{name}: missing heading" if missing?(section["heading"])
        errors << "#{name}: needs paragraphs or groups" if section["paragraphs"].blank? && section["groups"].blank?
        errors << "#{name}: paragraphs must be a list of text" unless section["paragraphs"].nil? || (section["paragraphs"].is_a?(Array) && section["paragraphs"].none? { |p| missing?(p) || !p.is_a?(String) })
        errors + group_errors(section["groups"], where: name)
      end
    end

    # nil, or a string of nothing but whitespace.
    def missing?(value) = value.nil? || (value.is_a?(String) && value.strip.empty?)

    private

    def cache = @cache ||= {}

    def pair?(hash, *keys) = hash.is_a?(Hash) && keys.none? { |key| missing?(hash[key]) }

    def group_errors(groups, where:)
      return [] if groups.nil?
      return [ "#{where}: groups must be a list" ] unless groups.is_a?(Array)

      groups.each_with_index.flat_map do |group, g|
        next [ "#{where}.groups[#{g + 1}] needs a title and a list of rows" ] unless group.is_a?(Hash) && !missing?(group["title"]) && group["rows"].is_a?(Array)

        group["rows"].each_with_index.filter_map do |row, r|
          "#{where}.groups[#{g + 1}].rows[#{r + 1}] needs k and v" unless pair?(row, "k", "v")
        end
      end
    end
  end
end

# frozen_string_literal: true

# The projects /work lists, read from content/work.yml into Data objects
# (design doc, section 2).
#
#   Portfolio.all.map(&:key)                  # => ["rails-rocket-sheep", ...]
#   Portfolio.fetch("rails-rocket-sheep").name
#
# A project is a key (its URL), a name, a one-line summary, a category, tags
# (its language and stack, shown as chips on /work), links and sections. /work
# shows the categories in CATEGORIES order.
# Sections and links take the shape a page's do, and are read and checked by
# SitePage. The file's order is the list's order.
#
# Every word comes from the file (docs/rules/content-is-files.md); copy not yet
# written stays in [brackets] (docs/rules/no-invented-content.md).
module Portfolio
  PATH = Rails.root.join("content/work.yml")

  REQUIRED = %w[key name summary category].freeze
  OPTIONAL = %w[tags links sections].freeze
  # A key is the project's URL segment.
  KEY = /\A[a-z0-9]+(-[a-z0-9]+)*\z/
  # The headings /work groups projects under, in the order it shows them.
  CATEGORIES = [ "AI and Tooling", "Applications", "Languages and Compilers" ].freeze

  Invalid = Class.new(StandardError)
  # No such project. config/application.rb answers it with a 404.
  NotFound = Class.new(StandardError)

  Project = Data.define(:key, :name, :summary, :category, :tags, :links, :sections)

  class << self
    # Outside development the file is read once.
    def all
      return load(PATH) if Rails.env.development?

      @all ||= load(PATH)
    end

    # Each category with its projects, in file order; an empty category is left out.
    def grouped = CATEGORIES.filter_map { |category| [ category, all.select { |project| project.category == category } ].freeze if all.any? { |project| project.category == category } }.freeze

    # @raise [NotFound] when no project has the key
    def fetch(key) = all.find { |project| project.key == key.to_s } || raise(NotFound, "no project #{key} in #{PATH.basename}")

    # @raise [Invalid] naming the file and every problem found
    def load(path)
      data = YAML.safe_load_file(path, freeze: true)
      errors = file_errors(data)
      raise Invalid, errors.map { |error| "#{File.basename(path)}: #{error}" }.join("\n") if errors.any?

      data["projects"].map do |project|
        Project.new(key: project["key"], name: project["name"], summary: project["summary"], category: project["category"],
          tags: Array(project["tags"]).freeze,
          links: SitePage.links(project["links"]), sections: SitePage.sections(project["sections"]))
      end.freeze
    end

    private

    def file_errors(data)
      return [ "top level must be a mapping with a list of projects" ] unless data.is_a?(Hash) && data["projects"].is_a?(Array)

      projects = data["projects"]
      errors = (data.keys - %w[projects]).map { |key| "unknown top-level key #{key}" }
      errors << "no projects" if projects.empty?
      keys = projects.filter_map { |project| project["key"] if project.is_a?(Hash) }
      errors += keys.tally.select { |_, count| count > 1 }.keys.map { |key| "#{key}: key used by more than one project" }
      errors + projects.each_with_index.flat_map { |project, index| project_errors(project, index) }
    end

    def project_errors(project, index)
      return [ "project #{index + 1}: must be a mapping" ] unless project.is_a?(Hash)

      name = project["key"].presence || "project #{index + 1}"
      errors = REQUIRED.select { |key| SitePage.missing?(project[key]) }.map { |key| "missing #{key}" }
      errors += (project.keys - REQUIRED - OPTIONAL).map { |key| "unknown key #{key}" }
      errors << "key must be lowercase letters, digits and single hyphens" if project["key"].is_a?(String) && !project["key"].match?(KEY)
      errors += tag_errors(project["tags"])
      errors << "category must be one of #{CATEGORIES.join(', ')}" unless SitePage.missing?(project["category"]) || CATEGORIES.include?(project["category"])
      errors += SitePage.link_errors(project["links"]) + SitePage.section_errors(project["sections"])
      errors.map { |error| "#{name}: #{error}" }
    end

    # Tags are optional; each one must be a chip in StackRegistry.
    def tag_errors(tags)
      return [] if tags.nil?
      return [ "tags must be a list of words" ] unless tags.is_a?(Array) && tags.all? { |tag| tag.is_a?(String) && tag.present? }

      tags.reject { |tag| StackRegistry.find(tag) }.map { |tag| "tag #{tag} is not in StackRegistry" }
    end
  end
end

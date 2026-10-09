# frozen_string_literal: true

# The projects /work lists, read from content/work.yml into Data objects
# (design doc, section 2).
#
#   Portfolio.all.map(&:key)                  # => ["rails-rocket-sheep", ...]
#   Portfolio.fetch("rails-rocket-sheep").name
#
# A project is a key (its URL), a name, a one-line summary, links, sections and
# findings. Sections and links take the shape a page's do, and are read and
# checked by SitePage. A finding is what the project taught: a kind, a title, a
# body and, optionally, a link to its evidence (docs/system/project-entries.md).
# The file's order is the list's order.
#
# Every word comes from the file (docs/rules/content-is-files.md); copy not yet
# written stays in [brackets] (docs/rules/no-invented-content.md).
module Portfolio
  PATH = Rails.root.join("content/work.yml")

  REQUIRED = %w[key name summary].freeze
  OPTIONAL = %w[links sections findings].freeze
  # What a finding can be. FindingMarkComponent draws a shape for each.
  KINDS = %w[learning surprise takeaway].freeze
  FINDING_REQUIRED = %w[kind title body].freeze
  FINDING_OPTIONAL = %w[evidence].freeze
  # A key is the project's URL segment.
  KEY = /\A[a-z0-9]+(-[a-z0-9]+)*\z/

  Invalid = Class.new(StandardError)
  # No such project. config/application.rb answers it with a 404.
  NotFound = Class.new(StandardError)

  Project = Data.define(:key, :name, :summary, :links, :sections, :findings)
  # evidence is a SitePage::Link, or nil.
  Finding = Data.define(:kind, :title, :body, :evidence)

  class << self
    # Outside development the file is read once.
    def all
      return load(PATH) if Rails.env.development?

      @all ||= load(PATH)
    end

    # @raise [NotFound] when no project has the key
    def fetch(key) = all.find { |project| project.key == key.to_s } || raise(NotFound, "no project #{key} in #{PATH.basename}")

    # @raise [Invalid] naming the file and every problem found
    def load(path)
      data = YAML.safe_load_file(path, freeze: true)
      errors = file_errors(data)
      raise Invalid, errors.map { |error| "#{File.basename(path)}: #{error}" }.join("\n") if errors.any?

      data["projects"].map do |project|
        Project.new(key: project["key"], name: project["name"], summary: project["summary"],
          links: SitePage.links(project["links"]), sections: SitePage.sections(project["sections"]),
          findings: findings(project["findings"]))
      end.freeze
    end

    def findings(list)
      Array(list).map do |finding|
        evidence = finding["evidence"] && SitePage.links([ finding["evidence"] ]).first
        Finding.new(kind: finding["kind"], title: finding["title"], body: finding["body"], evidence:)
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
      errors += SitePage.link_errors(project["links"]) + SitePage.section_errors(project["sections"]) +
        finding_errors(project["findings"])
      errors.map { |error| "#{name}: #{error}" }
    end

    def finding_errors(findings)
      return [] if findings.nil?
      return [ "findings must be a list" ] unless findings.is_a?(Array)

      findings.each_with_index.flat_map do |finding, index|
        name = "findings[#{index + 1}]"
        next [ "#{name}: must be a mapping" ] unless finding.is_a?(Hash)

        errors = KINDS.include?(finding["kind"]) ? [] : [ "#{name}: kind must be #{KINDS.to_sentence(last_word_connector: ' or ')}" ]
        errors += %w[title body].select { |key| SitePage.missing?(finding[key]) }.map { |key| "#{name}: missing #{key}" }
        errors += (finding.keys - FINDING_REQUIRED - FINDING_OPTIONAL).map { |key| "#{name}: unknown key #{key}" }
        errors += SitePage.one_link_errors(finding["evidence"], "#{name}.evidence") if finding.key?("evidence")
        errors
      end
    end
  end
end

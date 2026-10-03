# frozen_string_literal: true

# The threads in content/threads/*.yml, read into Data objects.
#
# A thread is one feature moving through the delivery chain, step by step. The
# home page plays one. The copy, the step kinds and the git topology all live in
# the YAML (docs/rules/content-is-files.md); this module only reads it and
# refuses a file that would draw a broken page.
#
#   DeliveryThread.fetch(:home).steps.first.name   # => "/pick"
#
# Loading validates, so a malformed thread fails at the first read rather than
# rendering wrong. The checks are the thread schema gate: required and known
# keys, allowed values, exactly one start and one end, and a merge for every
# fork. test/lib/delivery_thread_test.rb loads every file in content/threads.
#
# Named DeliveryThread, not Thread: Thread is a Ruby core class.
module DeliveryThread
  ROOT = Rails.root.join("content/threads")

  KINDS = %w[command human machine optional].freeze
  LANES = %w[human agent ci].freeze
  BAYS = [ "Todo", "In Progress", "Up for Review", "Done" ].freeze
  BRANCHES = %w[main feature side].freeze
  EVENTS = %w[start fork merge loop end].freeze

  REQUIRED = %w[key name kind lane bay outcome body git groups].freeze
  OPTIONAL = %w[artifact note seconds].freeze

  Invalid = Class.new(StandardError)

  Sequence = Data.define(:id, :title, :steps)

  Step = Data.define(:key, :name, :kind, :lane, :bay, :outcome, :body, :git, :groups, :artifact, :note, :seconds)

  Git = Data.define(:on, :event, :from, :label)
  Group = Data.define(:title, :rows)
  Row = Data.define(:key, :value)
  Artifact = Data.define(:source, :body)

  class << self
    # @raise [KeyError] when no content/threads/<id>.yml exists
    # @raise [Invalid] when the file breaks the schema
    # The id is matched against the files that exist, never joined into a
    # path, so an id like "../../config/database" names no thread.
    # Outside development a thread is read once, and a cache hit touches no
    # file at all.
    def fetch(id)
      return cache[id.to_s] if cache.key?(id.to_s) && !Rails.env.development?

      path = ROOT.glob("*.yml").find { |file| file.basename(".yml").to_s == id.to_s }
      raise KeyError, "no thread #{id} in #{ROOT}" unless path
      return load(path) if Rails.env.development?

      cache[id.to_s] = load(path)
    end

    def all = ROOT.glob("*.yml").sort.map { |path| fetch(path.basename(".yml")) }

    # @raise [Invalid] naming the file and step for every problem found
    def load(path)
      data = YAML.safe_load_file(path, freeze: true)
      errors = Schema.new(data, id: File.basename(path, ".yml")).errors
      raise Invalid, errors.map { |error| "#{File.basename(path)}: #{error}" }.join("\n") if errors.any?

      build(data)
    end

    private

    def cache = @cache ||= {}

    def build(data)
      steps = data["steps"].map do |step|
        Step.new(
          key: step["key"], name: step["name"], kind: step["kind"], lane: step["lane"], bay: step["bay"],
          outcome: step["outcome"], body: step["body"],
          git: Git.new(on: git_on(step["git"]), event: step["git"]["event"], from: step["git"]["from"], label: step["git"]["label"]),
          groups: step["groups"].map { |group| Group.new(title: group["title"], rows: group["rows"].map { |row| Row.new(key: row["k"], value: row["v"]) }.freeze) }.freeze,
          artifact: (Artifact.new(source: step["artifact"]["source"], body: step["artifact"]["body"]) if step["artifact"]),
          note: step["note"], seconds: step["seconds"]
        )
      end
      Sequence.new(id: data["id"], title: data["title"], steps: steps.freeze)
    end
  end

  # YAML 1.1 reads a bare `on:` key as the boolean true, so `git: { on: main }`
  # arrives as { true => "main" }. Accept both rather than make every editor of
  # the content quote the key.
  def self.git_on(git) = git.key?("on") ? git["on"] : git[true]

  # Every problem in one pass, so a broken file is fixed in one edit.
  class Schema
    def initialize(data, id:)
      @data = data
      @id = id
    end

    def errors
      return [ "top level must be a mapping with id, title and steps" ] unless @data.is_a?(Hash) && @data["steps"].is_a?(Array)

      steps = @data["steps"]
      id_errors + steps.each_with_index.flat_map { |step, index| step_errors(step, index) } +
        duplicate_key_errors(steps) + topology_errors(steps)
    end

    private

    def id_errors
      @data["id"] == @id ? [] : [ "id #{@data['id'].inspect} does not match the filename #{@id}.yml" ]
    end

    def duplicate_key_errors(steps)
      keys = steps.filter_map { |step| step["key"] if step.is_a?(Hash) }
      keys.tally.select { |_, count| count > 1 }.keys.map { |key| "#{key}: key used by more than one step" }
    end

    def step_errors(step, index)
      return [ "step #{index + 1}: must be a mapping" ] unless step.is_a?(Hash)

      name = step["key"].presence || "step #{index + 1}"
      errors = REQUIRED.select { |key| missing?(step[key]) }.map { |key| "missing #{key}" }
      errors += (step.keys - REQUIRED - OPTIONAL).map { |key| "unknown key #{key}" }
      errors << allowed("kind", step["kind"], KINDS)
      errors << allowed("lane", step["lane"], LANES)
      errors << allowed("bay", step["bay"], BAYS)
      errors += git_errors(step["git"]) + group_errors(step["groups"])
      errors << "artifact needs a source and a body" if step.key?("artifact") && !pair?(step["artifact"], "source", "body")
      errors << "seconds must be a positive whole number" if step.key?("seconds") && !(step["seconds"].is_a?(Integer) && step["seconds"].positive?)
      errors.compact.map { |error| "#{name}: #{error}" }
    end

    # nil, or a string of nothing but whitespace. An empty list is a value.
    def missing?(value) = value.nil? || (value.is_a?(String) && value.strip.empty?)

    def pair?(hash, *keys) = hash.is_a?(Hash) && keys.none? { |key| missing?(hash[key]) }

    def git_errors(git)
      return [] if git.nil? # reported as missing
      return [ "git must be a mapping with on, and optionally event, from and label" ] unless git.is_a?(Hash)
      return [ "git.on is required" ] if missing?(DeliveryThread.git_on(git))

      [ allowed("git.on", DeliveryThread.git_on(git), BRANCHES),
        (allowed("git.event", git["event"], EVENTS) if git.key?("event")) ]
    end

    def group_errors(groups)
      return [] if groups.nil? # reported as missing
      return [ "groups must be a list" ] unless groups.is_a?(Array)

      groups.each_with_index.flat_map do |group, g|
        next [ "groups[#{g + 1}] needs a title and a list of rows" ] unless group.is_a?(Hash) && !missing?(group["title"]) && group["rows"].is_a?(Array)

        group["rows"].each_with_index.filter_map do |row, r|
          "groups[#{g + 1}].rows[#{r + 1}] needs k and v" unless pair?(row, "k", "v")
        end
      end
    end

    def allowed(field, value, values)
      "#{field} #{value.inspect} is not one of #{values.join(', ')}" if value && !values.include?(value)
    end

    def topology_errors(steps)
      gits = steps.map { |step| step.is_a?(Hash) && step["git"].is_a?(Hash) ? step["git"] : {} }
      errors = %w[start end].filter_map do |event|
        count = gits.count { |git| git["event"] == event }
        "exactly one #{event}, found #{count}" unless count == 1
      end

      gits.each_with_index do |git, index|
        next unless git["event"] == "fork"

        branch = DeliveryThread.git_on(git)
        merged = gits.drop(index + 1).any? { |later| later["event"] == "merge" && later["from"] == branch }
        errors << "#{steps[index]['key']}: fork onto #{branch} never merges back" unless merged
      end
      errors
    end
  end
end

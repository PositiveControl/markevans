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
  # The threads a route reads. Each must exist: content:schema fails without
  # one, rather than leave its route to raise on the live site.
  ROUTED = %w[home].freeze

  KINDS = %w[command human machine optional].freeze
  # The kinds that are a gate: a step that clears or holds, not a command.
  GATES = %w[human machine].freeze
  LANES = %w[human agent ci].freeze
  # A lane as the strip's Ctl cell and the scope's centre block name it.
  LANE_NAMES = { "human" => "Human", "agent" => "Agent", "ci" => "CI" }.freeze
  BAYS = [ "Todo", "In Progress", "Up for Review", "Done" ].freeze
  BRANCHES = %w[main feature side].freeze
  EVENTS = %w[start fork merge loop end].freeze

  REQUIRED = %w[key name kind lane bay outcome body git groups].freeze
  OPTIONAL = %w[artifact note seconds].freeze
  GIT_KEYS = %w[on event from label].freeze
  ARTIFACT_KEYS = %w[source body url].freeze
  # headline and intro are the page copy around the thread: the h1 and the
  # paragraph beneath it. headline_link links one phrase of the headline off
  # the site; the headline itself stays plain text for the meta description.
  TOP_KEYS = %w[id title headline headline_link intro steps].freeze
  LINK_KEYS = %w[text url].freeze

  Invalid = Class.new(StandardError)

  Link = Data.define(:text, :url)

  Sequence = Data.define(:id, :title, :headline, :headline_link, :intro, :steps) do
    # Each step with what its own git block cannot say about its row in the
    # chart, so the chart is drawn from data and never from a row's position
    # (docs/rules/topology-from-data.md).
    def cells
      open = []
      above = nil
      steps.map do |step|
        open.delete(step.git.from) if step.git.event == "merge"
        cell = Cell.new(step:, through: open.dup.freeze, sector: (step.bay unless step.bay == above&.bay))
        open << step.git.on if step.git.event == "fork"
        above = step
        cell
      end.freeze
    end
  end

  # One row of the chart: the step, the branches other than main that run its
  # full height, and its bay when the row starts a sector (nil when it
  # continues the one above).
  Cell = Data.define(:step, :through, :sector)

  # Seconds a step plays for when it sets none (design doc, section 6).
  SECONDS = 6

  # Where each slash command a step names is defined: the template this
  # workflow ships in.
  COMMANDS_URL = "https://github.com/PositiveControl/rails-rocket-sheep/blob/main/.claude/commands"

  Command = Data.define(:name) do
    def path = ".claude/commands/#{name}.md"

    def url = "#{COMMANDS_URL}/#{name}.md"
  end

  Step = Data.define(:key, :name, :kind, :lane, :bay, :outcome, :body, :git, :groups, :artifact, :note, :seconds) do
    def duration = seconds || SECONDS

    def gate? = GATES.include?(kind)

    # The slash commands in the name, in order: "/segue → /segue_merge" names
    # two, "/pr_review --local" one, "Merge" none.
    def commands = name.scan(%r{(?<!\S)/(\w+)}).flatten.map { |command| Command.new(name: command) }
  end

  Git = Data.define(:on, :event, :from, :label)
  Group = Data.define(:title, :rows)
  Row = Data.define(:key, :value)
  Artifact = Data.define(:source, :body, :url) do
    def initialize(source:, body:, url: nil) = super
  end

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
          artifact: (Artifact.new(source: step["artifact"]["source"], body: step["artifact"]["body"], url: step["artifact"]["url"]) if step["artifact"]),
          note: step["note"], seconds: step["seconds"]
        )
      end
      link = (Link.new(text: data["headline_link"]["text"], url: data["headline_link"]["url"]) if data["headline_link"])
      Sequence.new(id: data["id"], title: data["title"], headline: data["headline"], headline_link: link, intro: data["intro"], steps: steps.freeze)
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
      header_errors + steps.each_with_index.flat_map { |step, index| step_errors(step, index) } +
        duplicate_key_errors(steps) + topology_errors(steps)
    end

    private

    def header_errors
      errors = @data["id"] == @id ? [] : [ "id #{@data['id'].inspect} does not match the filename #{@id}.yml" ]
      errors << "missing title" if missing?(@data["title"])
      errors += (@data.keys - TOP_KEYS).map { |key| "unknown top-level key #{key}" }
      errors += %w[headline intro].filter_map do |key|
        "#{key} must be text" if @data.key?(key) && !@data[key].is_a?(String)
      end
      @data.key?("headline_link") ? errors + headline_link_errors(@data["headline_link"]) : errors
    end

    def headline_link_errors(link)
      return [ "headline_link needs a text and a url" ] unless pair?(link, "text", "url")

      errors = (link.keys - LINK_KEYS).map { |key| "unknown headline_link key #{key}" }
      errors << "headline_link.url must start with https://" unless link["url"].to_s.start_with?("https://")
      errors << "headline_link.text must appear in the headline" unless @data["headline"].to_s.include?(link["text"].to_s)
      errors
    end

    def duplicate_key_errors(steps)
      keys = steps.filter_map { |step| step["key"].presence if step.is_a?(Hash) }
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
      errors += artifact_errors(step["artifact"]) if step.key?("artifact")
      errors << "seconds must be a positive whole number" if step.key?("seconds") && !(step["seconds"].is_a?(Integer) && step["seconds"].positive?)
      errors.compact.map { |error| "#{name}: #{error}" }
    end

    # nil, or a string of nothing but whitespace. An empty list is a value.
    def missing?(value) = value.nil? || (value.is_a?(String) && value.strip.empty?)

    def pair?(hash, *keys) = hash.is_a?(Hash) && keys.none? { |key| missing?(hash[key]) }

    # A url is optional and must be https, so a content edit cannot put a
    # javascript: or http: link on the page.
    def artifact_errors(artifact)
      return [ "artifact needs a source and a body" ] unless pair?(artifact, "source", "body")

      errors = (artifact.keys - ARTIFACT_KEYS).map { |key| "unknown artifact key #{key}" }
      errors << "artifact.url must start with https://" if artifact.key?("url") && !artifact["url"].to_s.start_with?("https://")
      errors
    end

    def git_errors(git)
      return [] if git.nil? # reported as missing
      return [ "git must be a mapping with on, and optionally event, from and label" ] unless git.is_a?(Hash)
      return [ "git.on is required" ] if missing?(DeliveryThread.git_on(git))

      errors = (git.keys - GIT_KEYS - [ true ]).map { |key| "unknown git key #{key}" }
      errors << allowed("git.on", DeliveryThread.git_on(git), BRANCHES)
      errors << allowed("git.event", git["event"], EVENTS) if git.key?("event")
      errors << allowed("git.from", git["from"], BRANCHES)
      errors << "a #{git['event']} needs git.from" if git["event"].in?(%w[fork merge loop]) && missing?(git["from"])
      errors
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
      "#{field} #{value.inspect} is not one of #{values.join(', ')}" unless value.nil? || values.include?(value)
    end

    def topology_errors(steps)
      gits = steps.map { |step| step.is_a?(Hash) && step["git"].is_a?(Hash) ? step["git"] : {} }
      errors = %w[start end].filter_map do |event|
        count = gits.count { |git| git["event"] == event }
        "exactly one #{event}, found #{count}" unless count == 1
      end

      errors += placement_errors(steps, gits) + line_errors(steps, gits)

      gits.each_with_index do |git, index|
        next unless git["event"] == "fork"

        branch = DeliveryThread.git_on(git)
        merged = gits.drop(index + 1).any? { |later| later["event"] == "merge" && later["from"] == branch }
        errors << "#{name_of(steps, index)}: fork onto #{branch} never merges back" unless merged
      end
      errors
    end

    def placement_errors(steps, gits)
      start = gits.index { |git| git["event"] == "start" }
      finish = gits.rindex { |git| git["event"] == "end" }
      [ ("#{name_of(steps, start)}: start must be the first step" if start&.nonzero?),
        ("#{name_of(steps, finish)}: end must be the last step" if finish && finish != gits.size - 1) ].compact
    end

    # Walks the thread in order, tracking which lines are open: main always,
    # a branch from its fork to its merge. A step may sit only on an open
    # line, and a side thread is a loop off one: side holds only loops, and
    # a loop sits only on side.
    def line_errors(steps, gits)
      open = [ "main" ]
      merged = []
      gits.each_with_index.flat_map do |git, index|
        name = name_of(steps, index)
        on = DeliveryThread.git_on(git)
        from = git["from"]
        errors = []

        case git["event"]
        when "fork"
          errors << "#{name}: fork from #{from}, which is not open here" if from && !open.include?(from)
          open << on
        when "merge"
          errors << "#{name}: merge from #{from}, which is not open here" if from && !open.include?(from)
          open.delete(from)
          merged << from
        when "loop"
          errors << "#{name}: loop from #{from}, which is not open here" if from && !open.include?(from)
          errors << "#{name}: a loop must be on side, not #{on}" if on && on != "side"
        end

        if on == "side"
          errors << "#{name}: on side must be a loop" unless git["event"] == "loop"
        elsif on && !open.include?(on)
          errors << "#{name}: on #{on}, which #{merged.include?(on) ? 'has already merged' : 'has not forked yet'}"
        end
        errors
      end
    end

    def name_of(steps, index) = (steps[index].is_a?(Hash) && steps[index]["key"].presence) || "step #{index + 1}"
  end
end

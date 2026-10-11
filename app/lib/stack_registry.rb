# frozen_string_literal: true

# The chips /work may show for a project's language and stack: each one's name,
# as written, and its kind. A project's `tags` in content/work.yml must name
# chips from here, so a typo fails the content schema instead of shipping.
#
#   StackRegistry["Ruby"].kind      # => :language
#   StackRegistry.find("COBOL")     # => nil
#
# The kind sets the chip's look in ChipComponent. Only a language stands out;
# no kind gets a color of its own, because color is reserved for roles
# (docs/rules/color-means-role.md).
module StackRegistry
  Chip = Data.define(:name, :kind) do
    def language? = kind == :language
  end

  KINDS = %i[language framework platform data tool hosting].freeze

  ITEMS = {
    language: %w[Ruby Python Go Swift GDScript OpenQASM],
    framework: %w[Rails ActionCable Godot MLX Minitest RSpec],
    platform: [ "iOS", "Apple Silicon", "IBM Quantum" ],
    data: %w[PostgreSQL SQLite],
    tool: %w[Claude Cursor Kamal RubyGems],
    hosting: %w[Hetzner]
  }.flat_map { |kind, names| names.map { |name| [ name, Chip.new(name:, kind:) ] } }.to_h.freeze

  class << self
    def [](name) = ITEMS.fetch(name)   # unknown name raises KeyError
    def find(name) = ITEMS[name]       # when a miss is legitimate
    def all = ITEMS.values
  end
end

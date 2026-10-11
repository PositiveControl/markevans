# frozen_string_literal: true

require "test_helper"

class StackRegistryTest < ActiveSupport::TestCase
  test "each chip has a kind from the fixed set" do
    assert StackRegistry.all.any?
    StackRegistry.all.each { |chip| assert_includes StackRegistry::KINDS, chip.kind, chip.name }
  end

  test "a chip is found by its name; an unknown name is nil or raises" do
    assert_equal :language, StackRegistry["Ruby"].kind
    assert_equal :hosting, StackRegistry["Hetzner"].kind
    assert_nil StackRegistry.find("COBOL")
    assert_raises(KeyError) { StackRegistry["COBOL"] }
  end

  test "every tag in content/work.yml is in the registry" do
    Portfolio.all.flat_map(&:tags).uniq.each { |tag| assert StackRegistry.find(tag), "#{tag} is not in StackRegistry" }
  end
end

# frozen_string_literal: true

require "test_helper"

# Steps come from the fixture thread in test/fixtures/files/threads, so every
# mark is shown to come from the data.
class DockedBarComponentTest < ViewComponent::TestCase
  test "the four controls, the step's name, the strip bay, and a mark per step" do
    render_bar

    assert_selector "button[data-action='playback#toggle'][data-playback-target=play]", visible: :all
    assert_selector "button[data-action^='playback#']", count: 4, visible: :all
    assert_selector "[data-playback-target=readoutName]", visible: :all
    assert_selector "[aria-label='Strip bay'] [data-playback-target=bay]", count: 4, visible: :all
    assert_selector "[data-playback-target=mark]", count: steps.size, visible: :all
  end

  test "each mark is a 44 px link to its step that jumps there, named for it" do
    render_bar

    marks = page.all("[data-playback-target=mark]", visible: :all)
    assert_equal steps.map { |step| "##{step.key}" }, marks.map { |mark| mark[:href] }
    assert_equal steps.each_index.map(&:to_s), marks.map { |mark| mark[:"data-playback-index-param"] }
    assert_equal "Go to step 1: /begin", marks.first[:"aria-label"]
    assert marks.all? { |mark| mark[:"data-action"] == "playback#jump" }
    assert marks.all? { |mark| mark[:class].split.include?("size-target") }
  end

  test "a mark is drawn as its step's scope target: a gate a rotated square, an optional step dashed" do
    render_bar

    assert_selector "[href='#gate'] span.rotate-45.border-human", visible: :all
    assert_selector "[href='#begin'] span.border-command:not(.rotate-45)", visible: :all
    assert_selector "[href='#aside'] span.border-dashed.border-quiet", visible: :all
  end

  test "hidden without scripts, and shown only while the page is docked" do
    render_bar

    bar = page.find("[aria-label='Docked playback']", visible: :all)
    assert bar[:hidden]
    assert_equal "live", bar[:"data-playback-target"]
    assert_includes bar[:class].split, "hidden"
    assert_includes bar[:class].split, "in-data-docked:block"
  end

  private

  def steps = DeliveryThread.load(file_fixture("threads/small.yml")).steps

  def render_bar = render_inline(DockedBarComponent.new(steps:))
end

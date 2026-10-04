# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "open3"

# bin/gates chdirs to its own repo root, so copy it into a throwaway tree and run
# it there against exactly the files each test writes.
class GatesLiteralColorTest < Minitest::Test
  GATES = File.expand_path("../../bin/gates", __dir__)

  def setup
    @root = Dir.mktmpdir
    FileUtils.mkdir_p(File.join(@root, "bin"))
    FileUtils.cp(GATES, File.join(@root, "bin/gates"))
  end

  def teardown
    FileUtils.rm_rf(@root)
  end

  def test_clean_tree_passes
    write "app/components/strip_component.rb", "class StripComponent; end\n"

    assert_equal 0, run_gates.last.exitstatus
  end

  def test_hex_in_a_component_fails
    write "app/components/strip_component/strip_component.html.slim", %(div class="text-[#0F7480]"\n)

    _, err, status = run_gates
    assert_equal 1, status.exitstatus
    assert_includes err, "app/components/strip_component/strip_component.html.slim:1: #0F7480"
  end

  def test_rgb_in_a_stylesheet_fails
    write "app/assets/tailwind/extra.css", ".x { color: rgba(27, 36, 40, 0.3); }\n"

    _, err, = run_gates
    assert_includes err, "app/assets/tailwind/extra.css:1: rgba("
  end

  def test_other_color_functions_fail
    write "app/assets/tailwind/extra.css", ".a { color: oklch(0.6 0.1 200); }\n.b { color: hsl(200 50% 40%); }\n"

    _, err, = run_gates
    assert_includes err, "extra.css:1: oklch("
    assert_includes err, "extra.css:2: hsl("
  end

  def test_hex_in_javascript_fails
    write "app/javascript/controllers/playback_controller.js", %(el.style.color = "#fff"\n)

    _, err, = run_gates
    assert_includes err, "playback_controller.js:1: #fff"
  end

  def test_hex_in_a_view_or_helper_fails
    write "app/views/home/show.html.slim", %(div class="text-[#0F7480]"\n)
    write "app/helpers/strip_helper.rb", %(COLOR = "rgb(1, 2, 3)"\n)

    _, err, = run_gates
    assert_includes err, "app/views/home/show.html.slim:1: #0F7480"
    assert_includes err, "app/helpers/strip_helper.rb:1: rgb("
  end

  # Known false positive, accepted: an anchor spelled only in hex letters reads
  # as a color. It fails closed, and the fix message says to rename the anchor.
  def test_an_anchor_spelled_in_hex_letters_is_flagged
    write "app/components/nav_component.rb", %(link_to "Feed", "#feed"\n)

    _, err, status = run_gates
    assert_equal 1, status.exitstatus
    assert_includes err, "nav_component.rb:1: #feed"
    assert_includes err, "rename the anchor"
  end

  def test_the_token_file_may_hold_literals
    write "app/assets/tailwind/tokens.css", "--color-ink: #1B2428;\n--color-rule: rgba(27,36,40,0.3);\n"

    assert_equal 0, run_gates.last.exitstatus
  end

  def test_the_app_stylesheet_is_not_exempt
    write "app/assets/tailwind/application.css", "@theme { --color-ink: #0a0a0b; }\n"

    _, err, status = run_gates
    assert_equal 1, status.exitstatus
    assert_includes err, "application.css:1: #0a0a0b"
  end

  def test_generated_builds_are_ignored
    write "app/assets/builds/tailwind.css", "a { color: #000; }\n"

    assert_equal 0, run_gates.last.exitstatus
  end

  def test_an_anchor_or_a_word_is_not_a_color
    write "app/components/nav_component.rb", %(link_to "Work", "#work"\nhref = "#deadbeefcafe"\n)

    assert_equal 0, run_gates.last.exitstatus
  end

  private

  def write(path, text)
    FileUtils.mkdir_p(File.dirname(File.join(@root, path)))
    File.write(File.join(@root, path), text)
  end

  def run_gates = Open3.capture3(File.join(@root, "bin/gates"))
end

# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "open3"

# bin/hooks/session_end reads the branch and the doc tree from its working
# directory, so drive it against a throwaway repo holding one Draft placeholder.
class SessionEndHookTest < Minitest::Test
  HOOK = File.expand_path("../../bin/hooks/session_end", __dir__)

  def setup
    @repo = Dir.mktmpdir
    git "init", "-q", "-b", "main"
    git "config", "user.email", "t@t"
    git "config", "user.name", "t"
    FileUtils.mkdir_p(File.join(@repo, "docs/plans"))
    File.write(File.join(@repo, "docs/plans/thing-design.md"), "# Thing\n\nStatus: Draft (created for #12)\n")
    git "add", "."
    git "commit", "-q", "-m", "init"
  end

  def teardown
    FileUtils.rm_rf(@repo)
  end

  def test_main_blocks_on_a_draft
    _, err, status = run_hook

    assert_equal 2, status.exitstatus
    assert_includes err, "docs/plans/thing-design.md"
  end

  def test_feature_branch_is_quiet
    git "switch", "-q", "-c", "feature/thing"

    assert_equal 0, run_hook.last.exitstatus
  end

  def test_slice_branch_blocks_on_its_own_draft
    git "switch", "-q", "-c", "me/12/thing"

    assert_equal 2, run_hook.last.exitstatus
  end

  def test_slice_branch_ignores_another_slices_draft
    git "switch", "-q", "-c", "me/13/other"

    assert_equal 0, run_hook.last.exitstatus
  end

  def test_detached_head_is_quiet
    git "switch", "-q", "--detach"

    assert_equal 0, run_hook.last.exitstatus
  end

  def test_skip_draft_check_silences_main
    assert_equal 0, run_hook("SKIP_DRAFT_CHECK" => "1").last.exitstatus
  end

  private

  def git(*args)
    _, status = Open3.capture2e("git", "-C", @repo, *args)
    raise "git #{args.join(' ')} failed" unless status.success?
  end

  # SKIP_DRAFT_CHECK is cleared by default, so a developer who has it set in
  # .claude/settings.local.json still gets real "blocks" results.
  def run_hook(env = {})
    Open3.capture3({ "SKIP_DRAFT_CHECK" => nil }.merge(env), HOOK, chdir: @repo)
  end
end

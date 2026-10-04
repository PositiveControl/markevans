require "test_helper"

# Development allows Markevans::TAILNET_HOST so the dev server works behind
# `tailscale serve`. The test environment never loads development's hosts, so
# the pattern is checked here through the matcher Rails wraps it in.
class TailnetHostTest < ActiveSupport::TestCase
  setup do
    @permissions = ActionDispatch::HostAuthorization::Permissions.new([ Markevans::TAILNET_HOST ])
  end

  test "allows a MagicDNS name, with or without a port" do
    assert @permissions.allows?("thinkserve.munchkin-tint.ts.net")
    assert @permissions.allows?("thinkserve.munchkin-tint.ts.net:8443")
    assert @permissions.allows?("THINKSERVE.Munchkin-Tint.ts.net")
  end

  test "blocks names that are not <machine>.<tailnet>.ts.net" do
    assert_not @permissions.allows?("ts.net")
    assert_not @permissions.allows?("tailnet.ts.net")
    assert_not @permissions.allows?("a.b.c.ts.net")
    assert_not @permissions.allows?("machine.tailnet.ts.net.evil.com")
    assert_not @permissions.allows?("evil.example.com")
  end
end

# The placeholder gate (docs/rules/no-invented-content.md).
#
# Content still to be supplied is written in square brackets — "[n]",
# "[Your note]" — or as TBD. That is fine on a branch and fatal on the live
# site, so this fails a production build and nothing else: it is wired in front
# of assets:precompile only when RAILS_ENV is production, which is what the
# Dockerfile builds with. It is deliberately not in bin/gates or CI, which would
# fail every push while the content is still being written.
#
# A bracket followed by "(" is a markdown link, not a placeholder.
namespace :content do
  desc "Fail if content/ holds a [placeholder] or TBD"
  task placeholders: :environment do
    root = Pathname(ENV.fetch("CONTENT_ROOT", Rails.root.join("content")))
    pattern = /\[[^\]\n]+\](?!\()|\bTBD\b/

    hits = root.glob("**/*.{yml,yaml,md}").sort.flat_map do |path|
      path.each_line.with_index(1).flat_map do |line, number|
        line.scan(pattern).map { |match| "#{path.relative_path_from(root)}:#{number}: #{match}" }
      end
    end

    if hits.any?
      warn "Placeholders left in #{root} — supply the content or remove the line:"
      hits.each { |hit| warn "  #{hit}" }
      exit 1
    end

    puts "content: no placeholders"
  end
end

Rake::Task.define_task("assets:precompile" => "content:placeholders") if Rails.env.production?

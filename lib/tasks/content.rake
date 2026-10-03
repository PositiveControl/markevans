# The content gates, run together by content:check ahead of a production build.
#
# content:schema loads every thread in content/threads/ through DeliveryThread,
# so a broken edit fails the build instead of the first request to the page.
#
# content:placeholders is the placeholder gate (docs/rules/no-invented-content.md).
# Content still to be supplied is written in square brackets, "[n]",
# "[Your note]", or as TBD. That is fine on a branch and fatal on the live site.
# Markdown's own brackets are not placeholders: a link "[text](url)", a
# reference link "[text][1]" and its "[1]: url" definition, and a checkbox
# "[ ]" or "[x]". YAML flow lists, "tags: [a, b]", would read as one, so content
# writes lists one item per line.
#
# content:check is wired in front of assets:precompile only when RAILS_ENV is
# production, which is what the Dockerfile builds with. It is deliberately not in
# bin/gates or CI: placeholders are expected there while the content is written,
# and the schema already runs in the test suite.
namespace :content do
  content_root = -> { Pathname(ENV.fetch("CONTENT_ROOT", Rails.root.join("content"))) }

  desc "Fail if a thread in content/threads breaks the schema"
  task schema: :environment do
    threads = content_root.call.join("threads").glob("*.yml").sort
    errors = threads.filter_map do |path|
      DeliveryThread.load(path)
      nil
    rescue DeliveryThread::Invalid => e
      e.message
    end

    if errors.any?
      warn "Threads that break the schema (docs/sop/edit-the-home-thread.md):"
      errors.each { |error| error.each_line { |line| warn "  #{line.chomp}" } }
      exit 1
    end

    puts "content: threads: #{threads.size} valid"
  end

  desc "Fail if content/ holds a [placeholder] or TBD"
  task placeholders: :environment do
    root = content_root.call
    pattern = /(?<!\])\[(?![ xX]\])[^\]\n]+\](?![(\[:])|\bTBD\b/

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

  desc "Run every content gate: the thread schema, then placeholders"
  task check: %w[content:schema content:placeholders]
end

Rake::Task.define_task("assets:precompile" => "content:check") if Rails.env.production?

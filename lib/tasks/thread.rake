# thread:export writes the root page as one HTML file that needs no server,
# network or script, for stepping through the thread by hand on a shared
# screen (docs/sop/export-the-thread.md). Run it through bin/export-thread,
# which sets RAILS_ENV=test so no database is touched (lib/thread_export.rb).
#
# The stylesheet is built first, so the file matches the views as they are.
# Placeholders in the threads the page renders (DeliveryThread::ROOT, whatever
# CONTENT_ROOT says) are reported but do not stop it: the file is for a
# meeting, not the live site, which content:check still guards.
namespace :thread do
  desc "Write the root page as one self-contained HTML file (OUT=path, default dist/delivery-thread.html; TITLE=, default uCollect Dev Workflow)"
  task export: %w[environment tailwindcss:build] do
    content = ENV["CONTENT_ROOT"]
    begin
      ENV["CONTENT_ROOT"] = DeliveryThread::ROOT.to_s
      Rake::Task["content:placeholders"].tap(&:reenable).invoke
    rescue SystemExit
      warn "thread:export: writing it anyway"
    ensure
      ENV["CONTENT_ROOT"] = content
    end

    out = Pathname(ENV.fetch("OUT", Rails.root.join("dist/delivery-thread.html")))
    out.dirname.mkpath
    out.write(ThreadExport.new(title: ENV.fetch("TITLE", "uCollect Dev Workflow")).call)
    puts "thread:export: wrote #{out} (#{out.size / 1000} kB)"
  end
end

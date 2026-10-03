# frozen_string_literal: true

# Content for the single-page personal site rendered by HomeController#index.
#
# Everything here is copy — it changes with a deploy, it is greppable, and no
# non-developer edits it. That is a registry, not a table. See
# docs/rules/registries.md.
module Portfolio
  Profile = Data.define(:name, :role, :location, :email, :github, :linkedin,
                        :tagline, :summary, :availability, :started)

  Metric = Data.define(:key, :value, :label, :detail)

  Role = Data.define(:key, :company, :title, :period, :context, :highlights)

  Project = Data.define(:key, :name, :kind, :url, :link_label, :blurb, :stack, :points)

  SkillGroup = Data.define(:title, :items)

  PROFILE = Profile.new(
    name: "Mark Evans",
    role: "Senior Software Engineer",
    location: "Phoenix, AZ",
    email: "msteven.evans@gmail.com",
    github: "https://github.com/PositiveControl",
    linkedin: "https://www.linkedin.com/in/sudobangbang",
    tagline: "I ship complete systems and keep them running.",
    summary: "Twelve years across Rails and distributed vehicle telemetry. Today I lead an " \
             "eight-person team day to day, hold merge authority, and run production for a " \
             "marketplace heading to public launch. Payments, auth, search, fulfillment, real-time " \
             "messaging, and an applied-AI pipeline built on the assumption that model output has " \
             "to be verified before anyone acts on it.",
    availability: "Open to senior and staff roles",
    started: 2014
  ).freeze

  METRICS = {
    page_load: Metric.new(
      key: :page_load,
      value: "20–25×",
      label: "Faster OCR entry point",
      detail: "Card-labeler initial load went from 20–25s to about 1s. The cause was un-indexed " \
              "scans over a 570k-row category table under a 128MB buffer pool. Fixed by " \
              "redesigning the query."
    ),
    requests: Metric.new(
      key: :requests,
      value: "7.8M",
      label: "Requests per day",
      detail: "Core contributor on a vehicle telemetry platform that went from zero to " \
              "always-connected fleets streaming continuously."
    ),
    rows: Metric.new(
      key: :rows,
      value: "2.4B",
      label: "Time-series rows per day",
      detail: "Binary telemetry ingested through ETL pipelines into TimescaleDB on PostgreSQL."
    ),
    coverage: Metric.new(
      key: :coverage,
      value: "40→90%",
      label: "Test coverage in 3 months",
      detail: "Then kept there. Test code still exceeds application code across my own projects."
    )
  }.freeze

  ROLES = {
    ucollect: Role.new(
      key: :ucollect,
      company: "Alpine Landing (uCollect)",
      title: "Software Engineer, day-to-day technical lead",
      period: "2025 – present",
      context: "Collectibles marketplace in production: grading submissions, auctions, offers, an " \
               "internal wallet, warehouse receiving, and AI card labeling. Rails 8, MySQL 8.4, Hotwire.",
      highlights: [
        "Primary reviewer and merge authority for a cross-functional team of eight, shipping large " \
        "features as reviewable stacked PR sequences.",
        "Built the proof-of-concept behind the multi-model card-recognition pipeline (Google Cloud " \
        "Vision OCR, a Gemini region advisor, a self-hosted Qwen vision cross-check) and maintain " \
        "it today after taking ownership back.",
        "Stood up and operate the self-hosted GPU inference host that serves the pipeline's local " \
        "vision model, vLLM on NVIDIA. Cloud or local is now a cost and privacy call we make per " \
        "workload.",
        "Made model output safe to merge into human work. Late OCR results land in the labeling " \
        "canvas in place, under a documented contract that will not clobber an annotator's manual " \
        "corrections.",
        "Shipped passwordless login with passkeys/WebAuthn end to end, plus step-up 2FA gating " \
        "profile changes, credential updates, and withdrawals.",
        "Built USDC deposits and withdrawals on Stripe Connect with idempotency keys and " \
        "cancel-on-failure rollback, and the offers/negotiation system around it.",
        "Designed and shipped the returns program end to end: data model, admin UI, batch returns, " \
        "EasyPost labels. Drove the returns policy decision itself.",
        "Took the application to production and operate the host: systemd, Puma, MySQL tuning, " \
        "connection-pool starvation, sort-memory failures, self-healing units for stale search pids."
      ]
    ),
    syberjet: Role.new(
      key: :syberjet,
      company: "ISSO, LLC (SyberJet Aircraft)",
      title: "Software Engineer",
      period: "2025 – present",
      context: "Light jet manufacturer. Concurrent role under common ownership with uCollect.",
      highlights: [
        "Built an in-cabin avionics display proof-of-concept in Flutter targeting NXP i.MX 8 " \
        "embedded Linux, used in development and in a demo simulator."
      ]
    ),
    nikola: Role.new(
      key: :nikola,
      company: "Nikola Motor",
      title: "Lead Engineer → Senior Engineer, Vehicle Software (Telematics)",
      period: "2020 – 2025",
      context: "Electric commercial-vehicle OEM. Promoted three times in five years; owned technical " \
               "direction for 8–10 engineers.",
      highlights: [
        "Built over-the-air firmware update orchestration end to end, from update creation through " \
        "delivery to vehicles.",
        "Designed device-to-cloud integration with the Controls and HMI teams, and automated ingestion " \
        "of vehicle DBC files for service technicians.",
        "Ran outsourced penetration testing and architecture review, authored the remediation plans, " \
        "and closed every medium- and high-severity finding.",
        "Owned platform stability. Resolved recurring downtime, tuned connection pooling, and ran " \
        "index audits with EXPLAIN/ANALYZE.",
        "Integrated SonarQube and Lattix static analysis into CI/CD alongside linting and coverage gates."
      ]
    ),
    earlier: Role.new(
      key: :earlier,
      company: "Golden Mean Solutions, American Red Cross, TeamSnap",
      title: "Software Developer → Engineer III",
      period: "2014 – 2020",
      context: "Greenfield EdTech and eCommerce builds, the Angular.js component library behind " \
               "redcross.org and redcrossblood.org, and RabbitMQ microservices serving mobile and web.",
      highlights: [
        "Before all of it: Air Traffic Controller, AC2 (AW), United States Navy. Facility rated " \
        "approach controller, tower and advanced radar certified."
      ]
    )
  }.freeze

  PROJECTS = {
    harness: Project.new(
      key: :harness,
      name: "harness",
      kind: "Local-first agent harness",
      url: "https://github.com/PositiveControl/harness",
      link_label: "github.com/PositiveControl/harness",
      blurb: "An autonomous execution loop that makes a local quantized 30B model reliable enough " \
             "to run unattended. Every observed failure becomes a deterministic guard in the harness.",
      stack: [ "Python", "MLX", "vLLM", "SQLite", "mypy --strict" ],
      points: [
        "Turn state machine (ASSESS → WRITE_TEST → IMPLEMENT → VERIFY → CLOSE) with halt reachable " \
        "from any phase, behind an operator approval gate.",
        "A critic loop that requires consecutive clean passes before declaring convergence, because " \
        "one clean pass can be a transient model artifact.",
        "Cite-grounded verification over 2,437 chunks of FAA phraseology regulation, under a " \
        "cite-or-silent policy that refuses when it has no source.",
        "Eleven eval suites and fixture-driven model selection; 4,231 tests against real SQLite " \
        "stores, no mocks."
      ]
    ),
    daily_drop: Project.new(
      key: :daily_drop,
      name: "Daily Drop",
      kind: "Music curation platform",
      url: "https://dailydrop.fm",
      link_label: "dailydrop.fm",
      blurb: "Multi-user daily music curation with taste-matching and subscriber communities. Songs " \
             "are never hosted here. One click exports them into the listener's own streaming account.",
      stack: [ "Rails 8", "Hotwire", "Swift/iOS", "Kamal 2" ],
      points: [
        "Passkeys/WebAuthn with password fallback; Apple Music (MusicKit) and Spotify OAuth and " \
        "playlist integration, including platform compliance work.",
        "~100 API endpoints, 43 models, 76 service objects, 38 background jobs on the Solid Stack.",
        "Native Swift client with a Live Activities widget extension and its own test suite.",
        "240 test files. Test code exceeds application code."
      ]
    ),
    idlempire: Project.new(
      key: :idlempire,
      name: "Idlempire",
      kind: "Multiplayer strategy game",
      url: "https://idlempire.com",
      link_label: "idlempire.com",
      blurb: "Adversarial multiplayer with an economy that has to stay balanced: combat engine and " \
             "simulator, alliance treasuries, diplomacy with escrow, and bots playing the live market.",
      stack: [ "Rails 8", "ActionCable", "PostgreSQL", "Docker" ],
      points: [
        "Fair-allocation production model, bounties, and era transitions across seasonal rounds.",
        "Real-time chat and comm panel over ActionCable; crypto wallet verification and staking.",
        "57 models, 49 services, 176 test files, 49k test LOC against 39k app LOC."
      ]
    ),
    kram: Project.new(
      key: :kram,
      name: "kraM",
      kind: "Reversible language + gate compiler",
      url: "https://github.com/PositiveControl/kraM",
      link_label: "github.com/PositiveControl/kraM",
      blurb: "A language whose programs run backward exactly, and a compiler backend lowering them to " \
             "elementary X/CNOT/Toffoli circuits.",
      stack: [ "Go", "OpenQASM", "IBM Quantum" ],
      points: [
        "An equivalence checker verifying every compiled circuit against the interpreter across " \
        "every basis state.",
        "Compiled circuits exported to OpenQASM and executed on IBM Quantum hardware: " \
        "Bernstein–Vazirani at 96.3%, Simon at 94.6%.",
        "The degraded runs are recorded next to the good ones: Grover at 53.9% against a 12.5% " \
        "noise floor."
      ]
    ),
    spam_sandwich: Project.new(
      key: :spam_sandwich,
      name: "Spam Sandwich",
      kind: "Phishing-awareness training",
      url: "https://spamsandwich.com",
      link_label: "spamsandwich.com",
      blurb: "A simulated inbox that tracks how people handle each message, with organization " \
             "enrollment, invitations, and achievements.",
      stack: [ "Rails 8", "Solid Stack", "Passkeys" ],
      points: [
        "The third product here using WebAuthn, alongside Daily Drop and the day job."
      ]
    ),
    slowpoke: Project.new(
      key: :slowpoke,
      name: "slowpoke-rb",
      kind: "Published Ruby gem, MIT",
      url: "https://rubygems.org/gems/slowpoke-rb",
      link_label: "rubygems.org/gems/slowpoke-rb",
      blurb: "Find your slow tests. Fast. Flags anything over a threshold across Minitest and RSpec.",
      stack: [ "Ruby", "Minitest", "RSpec" ],
      points: [
        "Zero runtime dependencies by design. In use on every project on this page."
      ]
    )
  }.freeze

  SKILL_GROUPS = [
    SkillGroup.new(
      title: "Daily driver",
      items: [ "Ruby", "Rails", "Hotwire", "PostgreSQL", "MySQL", "JavaScript", "Tailwind", "Linux", "Git" ]
    ),
    SkillGroup.new(
      title: "Also shipped to production",
      items: [ "Python", "Go", "Swift", "Flutter", "TimescaleDB", "RabbitMQ", "Docker", "Kamal",
              "Capistrano", "systemd", "GitHub Actions", "AWS", "Stripe", "ActionCable" ]
    ),
    SkillGroup.new(
      title: "Applied AI",
      items: [ "Multi-model OCR pipelines", "Vertex AI / Gemini", "Qwen VLMs", "self-hosted vLLM on NVIDIA",
              "MLX & Ollama", "agent orchestration", "retrieval & memory", "constrained decoding",
              "LLM eval harnesses" ]
    ),
    SkillGroup.new(
      title: "Security",
      items: [ "Passkeys / WebAuthn", "step-up 2FA", "device fingerprinting", "session management",
              "pen-test remediation", "Brakeman" ]
    ),
    SkillGroup.new(
      title: "How I work",
      items: [ "Test strategy & coverage programs", "flaky-test forensics", "VCR/WebMock", "system tests",
              "static analysis in CI", "incident response", "MySQL performance tuning", "ADRs",
              "stacked PRs", "mentoring" ]
    )
  ].freeze

  class << self
    def profile = PROFILE

    def metrics = METRICS.values

    def roles = ROLES.values

    def projects = PROJECTS.values

    def skill_groups = SKILL_GROUPS

    def project(key) = PROJECTS.fetch(key.to_sym)

    def role(key) = ROLES.fetch(key.to_sym)

    def metric(key) = METRICS.fetch(key.to_sym)

    # Whole years since the first professional role, for the hero metadata block.
    # Computed so it does not quietly go stale.
    def years_shipping(today = Date.current) = today.year - PROFILE.started
  end
end

# Writing — /writing, articles and the feed

**Status:** Draft — created for #58

The articles at `/writing` and `/writing/:slug`, read from `content/writing/`
by the `Writing` loader, and the Atom feed at `/writing.atom`. Design:
`docs/plans/2026-10-12-recruiter-search-design.md`, *Approach* §3.

Slice #58 fills this in: the front matter schema, `Writing::SERIES`, the
routes, the renderer and its sanitizing, the JSON-LD, the sitemap entries,
the feed and the tests.

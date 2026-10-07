# Export the thread

**Status:** Complete

How to turn the home page into one HTML file you can send, put on a shared
drive, or open on a meeting room's screen: no Rails, no database, no network.
The design is `docs/plans/2026-10-07-static-thread-export-design.md`.

---

## Make the file

```bash
bin/export-thread                       # dist/delivery-thread.html
bin/export-thread OUT=~/Desktop/thread.html
bin/export-thread TITLE="Another title"   # default: uCollect Dev Workflow
```

It builds the stylesheet, requests `/` from the app in process, and writes
about 260 kB to `dist/delivery-thread.html`. That file is committed, so it can
be downloaded from the repo; an `OUT=` path anywhere else in `dist/` is
ignored. The file is a snapshot and does not follow the content by itself:
after any change to `content/threads/home.yml` or the page's views, run it
again and commit the result with the change, or the committed copy is stale.

No server needs to be running, and no database either: the wrapper runs under
`RAILS_ENV=test`, where nothing on the page opens a connection.

Placeholders in `content/threads/` are listed as warnings and the file is
written anyway. Anything listed with a line number is a bracketed note the
audience will see, so supply it first if the file is going to be shown.

---

## What is in it, and what is not

The thread and nothing else, under its title: the title (uCollect Dev
Workflow unless `TITLE=` says otherwise, in the headline's place and style,
and on the browser tab) beside the legend, then every strip in order, each with its chart
cell and body. Every strip starts collapsed; click one to open its body, and
click it again to close it. The git graph beside a strip stretches and folds
with it. The fonts are inside the file.

The folding is the file's one script, inline, about fifteen lines. With
scripts off, the file reads as a document instead, every strip open
(`docs/system/home-thread-playback.md`, *Without scripts*).

Left out on purpose:

| Left out | Why |
|---|---|
| Playback, its controls, the strip bay, the log, the docked bar and the key list | The file is stepped through by hand. A clock running on its own fights the presenter |
| The controller filter | Same: it only works with playback's scripts |
| The site header and footer, the site's headline, the intro and the scope | The thread is the subject of the meeting, so the file is the thread and nothing else. The legend's "target on scope" key goes with the scope |
| The page's scripts, icons, canonical link and font preloads | A file that loads nothing cannot fail to load it |

If something on the page starts referencing a file the export cannot inline
(an image, a new kind of asset, a third-party URL), the export stops with
`ThreadExport::NotSelfContained` and names the reference. Its test fails the
same way (`test/lib/thread_export_test.rb`).

---

## Share it

- **Send it.** It is one file: attach it, or drop it on a shared drive. It
  opens from disk (`file://`) in any current browser.
- **Serve it on your tailnet,** for someone to review from their own machine.
  `tailscale serve` will only serve a directory as root (or an operator who
  can `sudo tailscale`), so serve `dist/` on localhost and proxy to that:

  ```bash
  python3 -m http.server 8090 --bind 127.0.0.1 --directory dist &
  tailscale serve --bg --https=8444 http://127.0.0.1:8090
  ```

  It is then at `https://<machine>.<tailnet>.ts.net:8444/delivery-thread.html`.
  Re-running `bin/export-thread` updates what it serves. To stop,
  `tailscale serve --https=8444 off` and stop the Python server. Use a port of
  its own, as `docs/sop/serve-dev-over-tailscale.md` explains for 8443. Checked
  with Tailscale 1.102.4.

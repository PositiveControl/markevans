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
```

It builds the stylesheet, requests `/` from the app in process, and writes
about 270 kB to `dist/` (ignored by git). Run it again after any change to
`content/threads/home.yml` or the page's views. The file is a snapshot and does
not follow the content by itself.

No server needs to be running, and no database either: the wrapper runs under
`RAILS_ENV=test`, where nothing on the page opens a connection.

Placeholders in `content/threads/` are listed as warnings and the file is
written anyway. Anything listed with a line number is a bracketed note the
audience will see, so supply it first if the file is going to be shown.

---

## What is in it, and what is not

The page as it reads without scripts (`docs/system/home-thread-playback.md`,
*Without scripts*): the headline and intro, the scope, the legend, and every
strip open in order, each with its chart cell and body. Each target on the
scope is a link to its step, so you step through by clicking a target or
scrolling. The fonts are inside the file.

Left out on purpose:

| Left out | Why |
|---|---|
| Playback, its controls, the strip bay, the log, the docked bar and the key list | The file is stepped through by hand. A clock running on its own fights the presenter |
| The controller filter | Same: it only works with playback's scripts |
| The header's Work, Workflow, Background and Contact links | The file has no other pages. The site name stays, as text |
| Every script, icon, canonical link and font preload | A file that loads nothing cannot fail to load it |

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

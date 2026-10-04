# Serve the dev server over Tailscale

**Status:** Complete

How to reach `bin/dev` from another device on your tailnet (a phone, a laptop)
over HTTPS, without binding Rails to a public interface.

---

## Set it up

Run Rails on localhost as usual, and give it its own `tailscale serve` HTTPS port:

```bash
bin/dev
tailscale serve --bg --https=8443 http://127.0.0.1:3000
```

The app is then at `https://<machine>.<tailnet>.ts.net:8443`. `tailscale serve
status` lists the routes; `tailscale serve --https=8443 off` removes this one.

Use a port of its own, not `/` on 443. Other tools take the root route for
themselves: T3 Code started with `--tailscale-serve` owns `/` and resets it when
it restarts. A Rails app also does not run cleanly under a sub-path.

Keep Rails on `127.0.0.1`. Binding it to the tailnet IP (`-b 100.x.y.z`) skips
HTTPS and exposes a second, unproxied way in.

---

## What the app does to allow it

`config/environments/development.rb` adds MagicDNS names to `config.hosts`:

```ruby
config.hosts << /[a-z0-9-]+\.[a-z0-9-]+\.ts\.net/i
```

It is a regex because Rails' leading-dot form (`".ts.net"`) matches exactly one
subdomain label, and a MagicDNS name has two. With the dot form every request
still gets `Blocked hosts: <machine>.<tailnet>.ts.net:8443`.

Development only. Production sets its own hosts in `config/environments/production.rb`.

---

## When it goes wrong

| Symptom | Cause |
|---|---|
| `Blocked hosts: ….ts.net:8443` | The server started before the hosts change. Restart `bin/dev`. |
| Forms return 422 with `HTTP Origin header (https://…) didn't match request.base_url (http://…)` in the log | Rails thinks the request was plain HTTP: the proxy did not send `X-Forwarded-Proto: https`. |
| The URL shows another app | The route points somewhere else. Check `tailscale serve status`. |

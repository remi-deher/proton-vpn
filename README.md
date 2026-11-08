# Proton VPN for Ryoku

Proton VPN in the Ryoku bar (niri). A port of
[OmaProton VPN](https://github.com/grichard99/omaproton-vpn) by grichard99
(built for Omarchy) to the Ryoku plugin system. It drives the official
`protonvpn` CLI; no credentials are stored by the plugin.

> Français : [README.fr.md](README.fr.md). Status: experimental.

## Install

```bash
ryoku plugin add ~/GitHub/ryoku-proton-vpn --bar --yes
```

Then click the Proton mark in the bar. The panel installs the CLI
(`proton-vpn-cli`), then signs you in.

## Use

| Action | Effect |
| --- | --- |
| Left click | Open the panel |
| Right click | Connect to the fastest server, or disconnect |
| Middle click | Force a status refresh |

The panel has a world map of every Proton city (the connected one is lit),
the power switch, live traffic, quick connect (Fastest, Random, P2P, Secure
Core, Tor), recent connections, a country and city browser, and the
protections: Kill Switch, NetShield, port forwarding, Always On.

## What it runs, reads and writes

- **Runs**: `protonvpn` (connect, status, config, sign-in via `bin/ryoproton-signin`), `nmcli` (tunnel
  state), `python3` helpers in `bin/` (read Proton's server cache), `cat` on
  `/sys/class/net/<dev>/statistics`, `busctl` (desktop notifications),
  `ryoku-app terminal` (opens your terminal for the sign-in prompt, which only
  accepts a tty), `flock` (serialises CLI calls).
- **Privileged**: on an explicit click on "Install Proton VPN CLI" only,
  `pkexec pacman -S --needed --noconfirm proton-vpn-cli`.
- **Reads**: `~/.cache/Proton/VPN/serverlist.json` (the client's own cache) and
  `~/.config/Proton/VPN/settings.json`.
- **Writes**: its state under `$XDG_STATE_HOME/ryoku/plugins/proton-vpn`
  (recents, profiles, notification icon), and Proton's own `settings.json` for
  split tunneling .
- **Network**: none of its own. The map is drawn offline from bundled Natural
  Earth data and the client's server cache, with no geo-IP lookup.

## Sign-in

A terminal opens for your password and 2FA code (the CLI only reads them from
a tty). If sign-in fails the terminal stays open so you can read the CLI's
message. Proton VPN CLI 1.0.5 asks for a security key by default; the plugin
passes `--totp` (authenticator code) unless you turn off *Sign in with an
authenticator code* in the plugin settings.

Use your Proton **username**, not your email: the CLI rejects the email with
"Authentication failed".

## Language

Follows the system locale (French or English). Force it with the *Language*
setting. Strings are translated at display time in `service/I18n.js`.

## Keyboard

Up/Down walk every row, Enter or Space activates, Left/Right change a value,
`/` jumps to the country search, `e` edits a profile, Escape leaves a field.

## Roadmap

Done: service, glyph, map, traffic, quick connect, profiles, recents,
countries/cities, Kill Switch, NetShield, port forwarding, Always On, split
tunneling, keyboard, French. Missing: `assets/preview-widget.png` (needs a real
capture of the open panel).

## Credits

Derived from [OmaProton VPN](https://github.com/grichard99/omaproton-vpn) (MIT,
© grichard99): the service logic, the CLI parsing, the Python helpers, the map
and traffic components. The land outline is Natural Earth (public domain). The
Proton mark is from Simple Icons (CC0). Not affiliated with Proton AG.

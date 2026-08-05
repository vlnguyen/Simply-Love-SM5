# Simply Love (ITGmania) — Online Lobby / Tournament Fork

![Arrow Logo](https://i.imgur.com/oZmxyGo.png)

This is a fork of [Simply Love](https://github.com/Simply-Love/Simply-Love-SM5), the ITGmania theme, built on top of the `itgmania-release` branch. It keeps everything from upstream Simply Love and adds a set of changes aimed at running online, lobby-based tournament events. For general information about Simply Love itself — installation, language support, aspect ratios, etc. — see the [upstream README](https://github.com/Simply-Love/Simply-Love-SM5/blob/itgmania-release/README.md).

This document only covers what's different in this fork.


## Connecting to an Online Lobby is now required (optional)

Upstream Simply Love already has an experimental "Enable Online Lobbies" option for connecting with other players over the internet. This fork adds a second option, **Require Lobbies** (found alongside it in *System Options → GrooveStats*), which is **on by default**.

While it's enabled, a banner reading "Connect to an online lobby to play" is shown on Select Music, all three Player Options screens, Gameplay, and Evaluation until you actually join a lobby. It disappears automatically as soon as you're connected, and reappears if you disconnect. Turn the option off if you want to play normally without a lobby connection.


## Your lobby code is now shown throughout the session

Once connected to a lobby, its code is now displayed in a few places it wasn't before:

- In the top-right corner of Select Music, where the game mode name normally appears.
- In the header of the Evaluation screen, same spot.
- In the header of the Player Options screens (e.g. "Select Modifiers (ABCD)").
- In place of "Event" on the stage indicator during gameplay, if you're playing in Event Mode.

This makes it easy to double check (or tell someone else) which lobby you're currently in without needing to back out to a menu.


## The lobby roster overlay is cleaner

The overlay listing everyone in your lobby has been condensed and cleaned up:

- Each player's current score is now shown compactly in parentheses next to their name (e.g. `1. PlayerName (91.42%)`) instead of on its own separate lines below the name.
- A player's score is hidden until they've actually started playing their song, so you don't see a meaningless "0.00%" while they're still readying up.
- Players are no longer numbered while everyone's still syncing up between screens — numbering (by current standing) only appears once gameplay is actually underway or during Evaluation.
- If you're playing local versus against someone else on your own machine, and nobody else from another machine has joined your lobby, the overlay hides itself entirely — there's no one else to sync with, so it just stays out of the way.


## Local versus games skip the manual ready-up

If you and a friend are playing local versus and you're the only two people in the lobby (i.e. no one from another machine has joined), both sides now auto-ready and gameplay starts immediately, rather than requiring you to each press Start to ready up. As soon as a third player from another machine joins your lobby, the normal ready-up flow returns.


## Tournament Mode score comparisons now consider the whole lobby

Previously, "who's winning" score highlighting (and the equivalent view in Step Statistics) only ever compared you against your local versus opponent. Now, during a Tournament Mode event with EX scoring, while connected to a lobby:

- Your score display dims unless you're currently in **1st place across the entire lobby** — not just ahead of whoever's next to you on the same machine.
- This works even if you're the only person playing on your machine; you're compared against everyone else in the lobby, not just a local opponent.
- If you and a friend are playing local versus and nobody else from another machine has joined, this falls back to the familiar local-only comparison, since the whole lobby is just the two of you anyway.

Outside of a Tournament Mode + EX scoring lobby event, score dimming behaves exactly as it always has.


## Step Statistics visibility fixes

A couple of display bugs affecting the Step Statistics pane during online lobby play have been fixed:

- The versus-style, split-screen Step Statistics layout no longer incorrectly appears for a single local player just because other players happen to be in the same online lobby — it now only shows up when there are actually two people playing on the same machine.
- When Tournament Mode is on and only one local player is on the machine, Step Statistics now correctly forces itself on for that player (matching the versus-mode behavior), rather than requiring the player to have manually selected it beforehand.


## Fantastic+ (W0) counts always shown during Tournament Mode EX scoring events

When Tournament Mode is enabled with EX scoring, Step Statistics now always breaks out Fantastic+ (W0) counts separately, regardless of whether you've personally turned on the Fantastic+ window preference. This keeps stat displays consistent across all players in a tournament event.

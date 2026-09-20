# NOVROS

**The No-VR Operating System.**

A desktop that lives over your camera feed. Windows, widgets, games and
settings float on glass in front of you, and you drive them with your
hands, your head, or an ordinary mouse. No headset. No controllers. No
gloves.

Built on **[barehands](https://github.com/jaredrhod/barehands)** by Jared
Rhodenizer, whose hand tracking is the engine underneath all of this.
NOVROS is a fork, and stays open under the same AGPL-3.0 terms.

---

## Run it

```
python3 server.py
```

Open **http://127.0.0.1:8794/stage.html** in Chrome and allow the camera.
The first run fetches the tracking models from a CDN, so it needs the
internet once; after that they are cached.

Nothing to install. The server is stdlib Python and the whole client is
one HTML file.

---

## What it is

Click the ring in the middle and six stations bloom around it —
**Widgets**, **Projects**, **Settings**, **Games**, **Demos**,
**Documents**.

**Three ways in, switchable at any time:**

| | |
|---|---|
| **Mouse** | click, drag, right-drag to rotate, wheel to scroll or resize, corner handles for resize and spin |
| **Hands** | point to aim, rest to open, press and hold to drag, two fingers to scroll, pinch to move, two hands to scale |
| **Head** | turn to aim, blink to open, double-blink for a file, wink to carry |

**Widgets** — clock, date, weather, and a live news ticker from the BBC,
the Guardian and Sky.

**Games** — Tetris, Space Invaders and Pac-Man, written for this board.

**Settings** — every threshold as a slider, a colour wheel that rotates
the whole interface, forced white or black text, and virtual backgrounds
with a hide-me mode.

---

## Make it yours

Point the stations at your own folders in `barehands.json`, then press
**R**:

```json
{
  "name": "NOVROS",
  "port": 8794,
  "orbs": [
    { "title": "Notes", "path": "~/MyVault", "kind": "notes" },
    { "title": "Props", "path": "media",     "kind": "media" }
  ]
}
```

A notes folder is just markdown, so an **Obsidian vault works as-is**.
Drop images, props and 3D models into `media/`, and backgrounds into
`media/backgrounds/`. Only files inside `media/` can ever reach the
board — that jail is a safety feature.

---

## Everything else

**Open the board and read `Getting Started` in the Documents station.**
Every control, every setting, every key and the whole tuning method live
there, so the documentation is inside the thing it documents.

Press **D** at any time for live gesture telemetry, and **P** to sample a
pose. Every threshold is live at `window.TUNE` in the console and takes
effect on the next frame.

---

## Credits

Hand and face tracking and person segmentation by
[Google MediaPipe](https://developers.google.com/mediapipe) (Apache 2.0).
3D by [three.js](https://threejs.org) (MIT). Weather from
[Open-Meteo](https://open-meteo.com). Both tracking libraries load from
public CDNs; this repo redistributes neither.

Built on [barehands](https://github.com/jaredrhod/barehands) by Jared
Rhodenizer.

## License

AGPL-3.0-or-later. Use it, change it, build on it, commercially and for
free. The one rule is that it stays open: if you pass your version on,
or run a modified version as a service, it ships under these same terms
with its source available. Full terms in `LICENSE`.

# NOVROS

The No-VR Operating System. A desktop that lives over your camera feed,
driven by your hands, your head, or an ordinary mouse. No headset, no
controllers, no gloves.



# Starting it

    python3 server.py

Then open **http://127.0.0.1:8794/stage.html** in Chrome and allow the
camera. Chrome specifically: its hand tracking is the proven path.

First run pulls the tracking models from Google's CDN, so it needs the
internet once. After that they are cached.


# The ring

NOVROS sits in the middle of the screen. Click it and six stations bloom
around it, evenly spaced:

    Widgets     clock, date, weather, news ticker
    Projects    yours to point somewhere
    Settings    every control in one panel
    Games       Tetris, Space Invaders, Asteroids
    Demos       the props folder
    Documents   your notes

Click the ring again to put them away. A station with nothing behind it
says so rather than failing silently — point it at a folder in
**barehands.json** and it fills.


# Three ways to drive it

Pick one from the buttons at the top right, or press **1** to **5**.
Mouse is on by default.


# The mouse

    click               open it
    drag                move it
    right-drag          tumble it in 3D
    right-click, still  flatten the rotation back out
    wheel               scroll a note, or resize a model or image
    shift + wheel       resize anything
    bottom-right corner drag to resize
    bottom-left corner  drag to spin in place
    the X, top right    close the window (it appears on hover)

Hold **shift** while rotating for fine control.


# Your hands

**Your index fingertip is the cursor. Your thumb is the button.** That
is the whole of it — there is no pose to hold and nothing to get right
before the hand will listen.

    one finger                 the arrow follows your fingertip
    ...arrow lights up         there is something under it to act on
    ...arrow turns red         you are over a close button
    thumb touches the index    BUTTON DOWN
    ...release without moving  click: it opens, or it closes
    ...move, then release      you dragged it there
    open your hand flat        always lets go, whatever else is true

**Closing a window** takes one of three things: its X, which appears when
you point at it; throwing it off the edge of the board; or the clap,
which clears everything. Nothing closes because you touched it -- a
window you are reading should not vanish under your hand.

    two fingers out            index and middle
    ...move up and down        scroll the pane under the cursor
    ...thumb touches them      RIGHT BUTTON
    ...tap                     put a rotated thing back flat
    ...hold and move           rotate it in 3D

    two hands                  scale
    clap                       sweep the board clean

A click is a press that did not travel. Hold it as long as you like —
there is no time limit, and being deliberate will not turn a click into
a drag.

The button is measured against **your own hand**: how far apart your
thumb and finger rest sets the threshold, so it fits your hand and your
camera angle without configuring anything. Seen from the side that gap
looks smaller than it is, which is why a fixed number could never work.

Every distance the tracker measures is a multiple of your own hand's
width on screen, so the controls feel the same on any display and at any
distance from the camera.


# The left hand

If both hands are in frame the left one drives the OS rather than being
a second mouse:

    open palm, held            the ring menu, in or out
    thumb pinch, tapped        close the front window
    two fingers, held          next input plane

# Your head

Press **H**. Look straight ahead while it centres, then:

    turn or tilt your head   move the cursor
    one deliberate blink     open a folder
    two blinks               open a file, or close what is open
    wink, move, wink again   carry something

A blink only counts if you meant it. Involuntary blinks are over in
about 130ms, so anything shorter is thrown away.


# Widgets

**Widgets** station. Clock, date, weather and a live news ticker from
the BBC, the Guardian and Sky. Click a row to put one on the board, click
it again to take it away. Whichever ones you had open come back after a
reload, where you left them.

Widgets close like any other window: point at one and press its X, or toggle its row off in the station.


# Games

**Games** station. Tetris, Space Invaders and Asteroids, written for this
board rather than borrowed. They are ordinary windows, so you can move,
scale, rotate and close them like anything else.

    arrows    move, or turn and thrust
    space     drop, or fire
    P         pause
    enter     restart after a game over

Keys go to whichever game you touched last.


# Settings

**Interface** — which input planes are live, and whether the mode bar
stays on screen.

**Colour** — the wheel at the top right picks any colour at all; the
presets here are shortcuts. Brightness bends the midtones without
flattening the contrast. **Text** forces white or black for backdrops
the tint cannot survive.

**Background** — none, blur, a flat colour, or any image in your media
folder. **Hide me** shows the backdrop alone with no camera in it.

**Hands** and **Head** — every threshold, as a slider. Nothing needs
applying; a change lands on the next frame.


# Your own things

**Notes** — the Documents station reads a folder of markdown. Point it
at an Obsidian vault and it works as it is.

**Props** — drop images in **media/misc/**, transparent props in
**media/fx/**, 3D models in **media/models/**, or **media/holo/** for
the same model as a blue wireframe.

**Backgrounds** — any image in **media/backgrounds/**.

Only files inside **media/** can ever reach the board. That jail is a
safety feature, not an inconvenience.

Edit **barehands.json**, then press **R** to re-read your folders.


# Keys

    R   respawn the board from disk
    C   cycle cameras
    D   debug overlay — fps and live gesture telemetry
    P   pose sampler, for fitting gestures to your hand
    H   head control on and off
    1-5 input planes


# When something misfires

Press **D**. The overlay prints what the tracker actually sees, which is
the difference between fixing a threshold and guessing at one.

Watch the **fps**. Hand tracking, head control and backgrounds are three
machine-learning models; running all three at once on a slow machine
will show here first. Add **?res=1280x720** to the URL to buy it back —
tracking loses nothing, because the models downscale every frame anyway.

Every threshold is live at **window.TUNE** in the console, and takes
effect on the next frame.

    TUNE.dwellMs = 90        select faster when you stop
    TUNE.dwellMoveBar = 2.6  more tolerant of a drifting hand
    TUNE.pointDipFrac = 0.88 an easier finger-press
    TUNE.rotSmooth = 0.1     heavier, slower rotation

**Nothing opens, but everything moves** — you opened the page as a file
instead of through the server. Start it with python3 and use the
127.0.0.1 address.

**Stuck on loading** — the first run needs the internet once, to fetch
the tracking models.

**Camera won't open** — another app has it. Press **C** to cycle.

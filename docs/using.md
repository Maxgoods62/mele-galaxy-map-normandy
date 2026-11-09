# Using Galaxy Map Normandy

This guide is for players. To install or uninstall the mod, see the [README](../README.md#install).

## What the mod changes

The galaxy map has four levels: the galaxy, a cluster, a system and a planet. The mod changes the cluster and system
levels:

- A lit SR-1 Normandy takes the place of the orange ring that marks the map cursor. The ship follows the cursor and
  turns its nose toward where it flies. Its engines glow, and blue beams trail behind them as it speeds up, as in
  Mass Effect 2.
- The ship has a flight sound, made from the Mass Effect 3 travel sound.
- The mouse works as in Mass Effect 2, with an arrow pointer and the Enter Orbit button.

The game's 2D "you are here" marker, a small ship outline in a ring, is gone at cluster and system level, where the
ship flies. The name labels stay. At galaxy level and in planet view, there is no ship and the map works as in the
normal game: the marker shows at galaxy level, and the game draws none in planet view.

## Controls

These controls work at cluster level and in system view.

### Mouse

| Input | What it does |
|---|---|
| Move the mouse | moves the arrow pointer |
| Hold the left button | the ship flies toward the arrow |
| Let go of the left button | the ship comes to a stop |
| Click the left button | selects what is highlighted |
| Click the Enter Orbit button | does what the button says |

The arrow appears on the ship when you start to move the mouse. It appears there again each time you move to another
level of the map. It moves like a desktop pointer without acceleration and stays on the screen.

While you hold the left button, the ship flies toward the arrow. The further away the arrow is, the faster the ship
flies, up to its top speed. It slows down as it gets close to the arrow, as if you eased a controller stick back. The
Flight speed setting changes how fast it flies.

A click is a press shorter than 0.25 s. It selects what is highlighted under the ship, as a click does in the normal
game. A longer press only flies the ship. When the ship is on something a click selects, it waits 0.25 s before it
flies, so a click does not move it. Anywhere else it sets off at once, and a click makes a short move. A stutter in the
game does not turn a click into a flight.

### The Enter Orbit button

The button shows at the bottom centre of the screen when the ship is on something you can enter. It offers what the
controller prompts offer there:

| Button | When it shows |
|---|---|
| Enter System | at cluster level, on a system |
| Enter Orbit | in system view, on a planet |
| Scan | on something you have not scanned yet |

The button does not show on things you cannot enter, such as an asteroid belt. It also hides while the map zooms from
one level to another.

A click on the button counts when you let go on it, however long you hold it. If you move the arrow off the button
before you let go, nothing happens. A press on the button never flies the ship.

It is the game's own button, the one LE1 shows in planet view, in the game's Domyouji font. Under the arrow it turns
brown and gold and its words turn white, as on the game's other buttons. With Myriad Pro Begone, which uses Domyouji
across the interface, the button matches the rest of it.

#### Languages of the button

The words are the ones Mass Effect 2 uses in each language. The mod follows the game's text language.

| Language | Enter System | Enter Orbit | Scan |
|---|---|---|---|
| English | Enter System | Enter Orbit | Scan |
| French | Entrer dans le système | Entrer dans l'orbite | Scanner |
| German | System anfliegen | Umlaufbahn anfliegen | Scannen |
| Italian | Entra nel sistema | Entra nell'orbita | Scansione |
| Spanish | Entrar en el sistema | Entrar en órbita | Explorar |
| Polish | Przejdź do układu | Wejdź na orbitę | Skanuj |
| Russian | Вход в систему | Выход на орбиту | Сканирование |
| Japanese | 星系に進入 | 軌道に入る | スキャン |

The longest words, such as the French Entrer dans le système, make the button a little wider.

### Controller

The controller keeps the normal game's controls. The stick moves the map cursor, and the ship follows it. The Flight
speed setting changes how fast the stick moves the cursor. At 100%, the map cursor moves at a little over half its
speed in the normal game at cluster level, and at about three quarters of it in system view. 200% at cluster level
and 125% in system view are close to the normal speed.

When you move the stick, the arrow hides until you move the mouse again. As soon as you touch the controller, the game
shows its controller prompts and the Enter Orbit button hides. A click or a key press brings the button back, but a
mouse move alone does not.

### When the arrow and the button hide

- While another window is open on top of the map, such as the travel prompt. The left button then works as in the
  normal game, so you can click that window.
- At galaxy level and in planet view. The mouse and the left button work there as in the normal game.
- After you use the controller, as described above.

## Sound

A whoosh plays each time the ship sets off. While the ship flies, an engine and a drive play. They get higher and louder
as the ship goes faster, and they fade out when it stops. When you close the map, all of the sound fades out. The
Flight sound volume setting sets how loud all three are.

## Settings

### Open the settings

Pause the game, open Mod Settings and pick Galaxy Map Normandy. Mod Settings is the Mod Settings Menu of the LE1
Community Patch, and the mod's row is on its first page.

### The settings page

The page has Flight sound volume first, then four settings for cluster level, the same four for system view, and
Restore defaults. The rows carry the level in their names, such as Cluster: flight speed and System: flight speed. Each
setting shows its value on the right, such as 100%.

| Setting | What it changes |
|---|---|
| Flight sound volume | how loud the whoosh, the engine and the drive are, at both levels |
| Flight speed | how fast the ship and the map cursor move |
| Turn rate | how fast the ship's nose turns toward where it flies |
| Ship response | how closely the ship follows the map cursor |
| Ship size | the size of the ship |

Flight speed works for the controller and the mouse alike. What is selected follows the map cursor, so it moves at
the flight speed too. In system view the camera follows the ship, so a higher flight speed also moves the view faster.

With a low ship response, the ship glides behind the map cursor. With a high one, it stays on the cursor.

### Steps and Restore defaults

Each setting opens a list of steps: 50%, 75%, 100%, 125%, 150% and 200%. 100% is the mod's default and is
marked (default). For the flight speed, 100% is slower than in the normal game. The step in use is green and marked
Current, and the list opens on it. Pick a step to use it. Back returns to the settings page.

Flight sound volume has its own list, from 0% to 140% in steps of 10%. 0% turns the flight sound off.

Restore defaults, the last row of the page, sets all nine settings back to 100%.

### Languages of the pages

The pages follow the game's text language: English, French, German, Italian, Spanish, Polish, Russian or Japanese. The
mod's name, on its row in Mod Settings and at the top of its pages, follows the language too, but no language has a
translation of it yet, so it reads Galaxy Map Normandy. The percents follow the language as the game writes them:
French shows 100 %, the other languages 100%. No native speaker has reviewed the translations.

A translation mod can replace every word of the pages and of the Enter button. The string ids and the files are in
[translating.md](translating.md).

### Where your choices are kept

The mod keeps your choices in the game's gamer profile. This is the file `Save\ME1\PROFILE\GamerProfile.pcsav` in
`Documents\BioWare\Mass Effect Legendary Edition`. So your choices are the same for every career and every save. The
mod writes the file as soon as you pick a step or Restore defaults.

Your choices apply the next time you open the galaxy map.

## Known issues

- In system view the game's camera follows the cursor. The ship stays near the middle of the screen while the system
  moves under it. Mass Effect 2 keeps that view still.
- What is selected follows the map cursor, which the mod hides. The ship eases after the cursor, so on a fast move the
  highlight can change a moment before the ship gets there.
- The mod has not been tested with other galaxy map mods.

## If something is wrong

Close the game before you change anything in ME3Tweaks Mod Manager (M3).

### No ship on the map

The ship shows only at cluster level and in system view. If the orange ring shows there instead, the game did not
load the mod. The LE1 Community Patch loads it with the Normandy, through its Sideloader, and the mod needs version 2.0
or later. In M3, select your LE1 game, click Manage Target and check that `DLC_MOD_GalaxyMapNormandy` and
`DLC_MOD_LE1CP` are both installed. Then install the mod again.

### No Galaxy Map Normandy row in Mod Settings

If you find no Mod Settings when you pause the game, the LE1 Community Patch is missing. Install version 2.0 or later.
If Mod Settings opens without a Galaxy Map Normandy row, install the mod again with M3.

### A setting changes nothing

Your choices apply the next time the map opens. Close the map and open it again.

### No arrow or no Enter Orbit button

Move the mouse to bring the arrow back. After you use the controller, click or press a key to bring the button back.
The button shows only when the ship is on something you can enter. Both hide while another window, such as the travel
prompt, is open on the map.

### Report a problem

Open an issue on [GitHub](https://github.com/Maxgoods62/mele-galaxy-map-normandy/issues) with the Bug report form.
Give the mod version, the Community Patch version and your other mods. For an install problem, add the M3 log (Help >
Mod Manager Logs & Game Diagnostics). For a problem in the game, a screenshot helps.

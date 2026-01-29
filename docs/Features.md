<!-- markdownlint-disable MD033 -->

# Features

SSV2 includes polished versions of your favorite features from previous versions before the rework plus some new additions.

<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#self">Self</a></li>
    <li>
      <a href="#vehicle">Vehicle</a>
      <ul>
        <li><a href="#general">General</a></li>
        <li><a href="#aircraft">Aircraft</a></li>
        <li><a href="#stancer">Stancer</a></li>
        <li><a href="#engine-swap">Engine Swap</a></li>
        <li><a href="#handling-editor">Handling Editor</a></li>
        <li><a href="#custom-paint-jobs">Custom Paint Jobs</a></li>
        <li><a href="#flatbed-script">Flatbed Script</a></li>
      </ul>
    </li>
    <li><a href="#world">World</a></li>
    <li>
      <a href="#online">Online</a>
      <ul>
        <li><a href="#yimresupplierv3">YimResupplierV3</a></li>
        <li><a href="#casinopacino">CasinoPacino</a></li>
        <li><a href="#salvageyard">SalvageYard</a></li>
      </ul>
    </li>
    <li>
      <a href="#extra">Extra</a>
      <ul>
        <li><a href="#yimactionsv3">YimActionsV3</a></li>
        <li><a href="#entityforge">EntityForge</a></li>
        <li><a href="#billionaire-services">Billionaire Services</a></li>
      </ul>
    </li>
  </ol>
</details>

## Self

_Player-centric features affecting movement, combat, and animations._

- **Auto-Heal**

  Constantly refills your health and armor.

- **Enable Phone Animations**

  Restores mobile phone animations in Online mode.

- **MC Riding Style**

  Enables alternate bike riding animations.

  _Usage:_ Automatically applies when riding a motorcycle at low speed.

- **Disable Action Mode**

  Disables the player's forced stance when in combat or wanted by the police.

- **Allow Head Props In Vehicles**

  Allows you to keep your headgear (hats, helmets, masks, etc.) inside vehicles.

- **Stand On Vehicles**

  Prevents you from ragdolling when standing on top of a moving vehicle.

- **No Carjacking**

  Prevents NPCs from carjacking you. Enemies will not try to open your vehicle's door and force you out.

- **Crouch**

  Allows you to crouch.

  _Usage:_ Toggle by pressing **[Left Control]**.

- **Hands Up**

  Allows you to put your hands up _(surrender)_. This replaces the **"Point At"** action in Online.

  _Usage:_ Toggle by pressing **[B]**.

- **Sprint Inside Interiors**

  Allows you to sprint at full speed inside _most_ interiors.

- **Lockpick Animation**

  Increases the chance of using a lock picking animation when stealing vehicles instead of smashing the window.

- **Ragdoll On Demand**

  Allows you to ragdoll at any time.

  _Usage:_ Triggered via keybind _(default: **[X]**)_.

- **Clumsy**

  Makes you stumble and fall whenever you bump into anything; including sidewalks.

- **Magic Bullet**

  Shoots the last ped you aimed at in the head as soon as you fire your weapon.

- **Laser Sights**

  Adds a visible laser beam to supported firearms.

  _Usage:_ Toggle via keybind while aiming, same as weapon flashlight _(default: **[L]**)_.

- **Katana**

  Replaces a selected melee weapon with a katana for close-quarters combat.

  _Usage:_ Choose base weapon in settings, then equip normally.

<p align="right">[<a href="#features">🔝</a>]</p>

## Vehicle

_Vehicle-centric features extending the capabilities of vanilla vehicles._

### General

- **Speedometer**

  Draws a custom speedometer that switches modes between vehicles and aircraft.

- **Brake Force Display**

  Flashes your brake lights when you apply the brakes from high speed.

- **Fast Vehicles**

  Greatly increases the acceleration and top speed of any land vehicle you drive.

- **NOS**

  Allows you to use a custom NOS boost.

  _Usage:_ Triggered via keybind while driving _(default: **[Left Shift]**)_.

- **NOS Purge**

  Allows you to perform a NOS purge [à la 2 Fast 2 Furious](https://www.youtube.com/watch?v=aBRCDqabqTE)

  _Usage:_ Triggered via keybind while driving _(default: **[X]**)_.

- **Pops & Bangs**

  Enables extremely loud exhaust pops that scare nearby NPCs.

  _Usage:_ Triggered automatically when you release the accelerator from high RPM.

- **Drift Mode**

  Introduces new arcade-style drift mechanics.

  _Usage:_ Triggered via keybind while driving _(default: **[Left Shift]**)_.

- **Big Subwoofer**

  Makes your vehicle's radio sound louder from the outside.

- **High Beams On Horn**

  Flashes your high beams when you use the horn.

- **Auto Brake Lights**

  Turns on your brake lights when you come to a complete stop.

- **Unbreakable Windows**

  Prevents your vehicle's windows from breaking.

- **Stronger Crashes**

  Makes car crashes more dangerous by increasing deformation, introducing engine damage, screen effects, and potential loss of life.

- **RGB Headlights**

  Starts an RGB loop on your vehicle's headlights.

- **Auto Lock**

  Automatically locks your vehicle when you walk away from it.

- **Launch Control**

  Simulates launch control by making your vehicle accelerate faster from a standstill and decreasing wheel spin.

- **IV-Style Exit**

  Re-introduces GTA IV's vehicle exit style.

  _Usage:_ Hold **[F]** to turn the engine off before exiting or press and release normally to keep it running.

- **Keep Wheels Turned**

  Preserves the last angle your wheels were steered at before exiting.

- **Vehicle Mines**

  Allows you to deploy all types of mines from any land vehicle.

  _Usage:_ Choose a type then press the assigned keybind _(default: **[Numpad 0]**)_.

- **Drift Minigame**

  Score points by drifting around Los Santos. You can bank your points for cash in Single Player.

- **Ram _(AKA Shunt)_**

  Gives you the ability to ram other vehicles, peds, or objects in 3 directions.

  _Usage:_ Triggered via keybinds while moving forward in a vehicle. **[Numpad4]**: Left | **[Numpad8]**: Forward | **[Numpad6]**: Right.

### Aircraft

- **Fast Planes**

  Increases the top speed of any plane you fly to ±560 km/h as long as the plane can reach 250 km/h on its own.

- **Disable Engine Stalling**

  Prevents your plane engine(s) from stalling when you hold the brake button mid-air.

- **Disable Air Turbulence _(Experimental)_**

  Disables air turbulence for some aircraft.

- **Flare Countermeasures**

  Allows you to deploy flares from any aircraft.

  _Usage:_ Triggered via default countermeasures keybind.

- **Cobra Maneuver**

  Allows you to perform a [cobra maneuver](https://www.youtube.com/shorts/H0X7D3Ga4mo).

  _Usage:_ Triggered via keybind while flying _(default: **[X]**)_.

- **Machine Gun Triggerbot**

  Automatically fires your aircraft's machine gun.

  _Usage:_ Get in a weaponized aircraft and equip the machine gun.

- **Machine Gun Manual Aim**

  Allows you to manually aim your aircraft's machine gun.

- **Autopilot**

  Automatically flies your aircraft to the selected destination.

  _Usage:_ Sit in the pilot's seat and select a destination from the menu _(Objective, Waypoint, or Random)_.

### Stancer

_VStancer's Carthaginian cousin._

Allows advanced stance tuning, including:

- **Per-axle _(affects handling)_**

  Camber, suspension height, track width.

- **Global _(visual only)_**

  Wheel size, wheel width, ride height.

Additional features:

- Air suspension controls.
- Bounce mode _(SUVs only)_.

### Engine Swap

Changes your current vehicle's engine sound and power.

### Handling Editor

Extends the pre-existing handling editor in YimMenu with more options focused on handling flags.

### Custom Paint Jobs

Choose from a list of over 300 hand-picked real-life paint jobs and apply them to your current vehicle.

### Flatbed Script

A script that allows you to use the [MTL Flatbed](https://gta.fandom.com/wiki/Flatbed) truck to tow vehicles. You can either spawn a truck yourself or find one in the open world.

_Usage:_ Sit in the driver's seat of a flatbed truck then approach any vehicle and press the assigned keybind _(default: **[X]**)_ to tow it.

<p align="right">[<a href="#features">🔝</a>]</p>

## World

- **Disable Ocean Waves**

  Completely removes waves from the ocean.

- **Extend World Boundaries**

  Allows you to travel further in any direction without dying.

- **Disable Flight Music**

  Disables the ambient music that automatically plays when you're flying an aircraft.

- **Disable Wanted Music**

  Disables the ambient music that automatically plays when you have a wanted level higher than 2 stars.

- **Hide & Seek**

  Allows you to hide in several places (car trunks, trash bins, inside vehicles). Also makes it easier to lose a wanted level.

- **Carpool**

  Allows you to get in any NPC vehicle as a passenger. Works for police vehicles too but they won't be happy.

- **Public Enemy #1**

  All nearby NPCs attack you.

- **Kill All Enemies**

  Kills all nearby enemies.

  _Usage:_ Triggered via a button in the UI or a keybind _(default: **[F7]**)_.

- **Scare All Enemies**

  Forces all nearby enemies to flee _(except NOOSE)_.

  _Usage:_ Triggered via a button in the UI or a keybind _(default: **[F8]**)_.

<p align="right">[<a href="#features">🔝</a>]</p>

## Online

### YimResupplierV3

A business manager that supports auto-fill and auto-sell for several businesses, offers instant production triggers for biker businesses, bunker, and acid lab, controls some job cooldowns, and integrates with CommandExecutor.

### CasinoPacino

An updated and slightly refactored version of [Casino Pacino](https://github.com/YimMenu-Lua/Casino-Pacino).

### SalvageYard

A script focused on the Chop Shop business. Added by [szalikdev](https://github.com/szalikdev).

## Extra

### YimActionsV3

A greatly improved version of my all-in-one animations script.

### EntityForge

An experimental script that allows you to attach, merge, and create things using peds, objects and vehicles and share them with friends.

### Billionaire Services

Offers exclusive bodyguard, escort, jet, heli, and limousine services.

<p align="right">[<a href="#features">🔝</a>]</p>

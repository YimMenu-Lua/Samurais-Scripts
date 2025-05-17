## Self

- **Main Self Features:**
  
  - **Auto-Heal:**
    - Constantly fills your health and armour whenever they fall below the maximum.
  
  - **~Teleport To Objective:~**
    - ~This was only added because the option in YimMenu was kind of broken~. [gir489returns](https://github.com/gir489returns) fixed it so this one was removed.
  
  - **Crouch Instead Of Sneak:**
    - Replaces the default sneaking stance (Left control) with crouching.

  - **Replace 'Point At' Action:**
    - Replaces the *Point At* action in Online (B) with *Hands Up*.

  - **Enable Phone Animations:**
    - Allows your online character to physically interact with their mobile phone.

  - **Sprint Inside Interiors:**
    - Allows your character to sprint at full speed inside a few interiors that normally don't allow it. Some other interiors like the bunker will still force you to run slowly.

  - **Use Lockpick Animation:**
    - When stealing cars, your character will pick the door lock instead of smashing the window. Note that this won't work on some missions and also if you approach the vehicle while running, your character will still break the window.

  - **Disable Action Mode:**
    - Keeps your character in their normal stance after firing a weapon instead of going into that janky movement stance R* calls *Action Mode*. So now for example after killing everyone in the Stash House, you can calmly walk to the safe instead of slamming into walls and being all over the place.

  - **Clumsy:**
    - Makes you stumble and fall when you collide with objects and sidewalks.

  - **Ragdoll On Demand:**
    - Gives you the ability to make your character fall whenever you want by pressing [X] on keyboard. Note that this feature can knock you off bikes whenever you press the button *(kinda funny)*.

  - **Ragdoll Sound:**
    - Online Only: Plays a hurt/panicked ped sound when the player ragdolls.

  - **Hide & Seek:**
    - When the option is enabled, you have 3 choices:
      1. Hide inside any vehicle's trunk (assuming the vehicle actually has a trunk). Approach the vehicle's trunk then when prompted, press **[E]** to hide inside.
      2. Hide inside dumpsters: Approach any dumpster then when prompted, press **[E]** to hide inside.
      3. **Only when you have a wanted level** -> Hide in your (or any) car: When you're wanted and not actively being seen by the cops, wait for the propt then press **[ENTER]** to hide inside your car.

      > **Note:** If you're driving then the prompt will only appear if the cops can't see you and you **stop your vehicle completely**. The vehicle doesn't have to be stopped if you're a passenger.
  
  - **Allow Hats In Vehicles:**
    - Prevents the game from removing your hat or headgear/accessories when you enter a vehicle.

  - **Don't Fall Off Vehicles:**
    - Allows you to stand on top of vehicles without falling off when the vehicle moves.

- **YimActions V3:**
  - [YimActions](https://github.com/xesdoog/YimActions) rebuilt from scratch.

- **Sound Player:**
  - Plays either human speeches or loud radio music that players nearby can hear (assuming you're not lagging and there are no sync issues).

## Weapon

- **Info Gun:**
  - A debug option that will be removed in the future. Simply aim your gun at a game entity and press **[Left Mouse Button]** to log information about it to the console.

- **Trigger Bot:**
  - A barebones and janky triggerbot. *Kinda works?* Only on foot though.

- **Magic Bullet:**
  - Different from an aimbot, this feature automatically shoots the last ped you aimed at in the head when you press [FIRE], regardless of whether your crosshair is still on the ped or not. The only requirement is that the ped has to be in your field of view and not too far away from you.
  - If you aim at a vehicle that has a driver, the magic bullet will automatically hit the driver in the head as soon as you fire your weapon.

- **Autokill Enemies:**
  - Automatically kills nearby enemies and destroys their vehicle if they are inside one.

- **Enemies Flee:**
  - All nearby enemies will drop their weapons and run away from you. Note that during some missions, enemies will be confused and sometimes stand still and scream in horror because the game is forcing them to attack and this script is forcing them to flee.

- **Katana:**
  - Replaces one of these melee weapons: **Baseball Bat**, **Golf Club**, **Machete**, or **Pool Que** with a Japanese katana. If you don't own the weapon, you can either buy one from Ammu-Nation or use YimMenu to equip a temporary one. Once you have one equipped in your hands, it will be automatically replaced with a Katana.

- **Laser Sight:**
  - Renders a laser sight on your weapons when you're aiming them. You can choose between Red, Green, and Blue lasers. Can be toggled on/off by pressing the assigned key *(default **[L]** on keyboard)* while aiming.

## Vehicle

- **All features from [TokyoDrift](https://github.com/YimMenu-Lua/TokyoDrift) with a few improvements and additions:**

  - **Better Drift Mode / Drift Tires:**
    - Increased torque while drifting so that you could pick up speed faster and hold bigger angles. You can choose how much torque you want to gain.

  - **Drift Smoke:**
    - Your tires will now produce a lot more smoke when drifting. The smoke will appear when you're drifting at a speed higher than *approx: 15mph // 20km/h*. You can change the smoke color either from a drop down list of pre-defined colors or by inputting your own [HEX](https://www.color-hex.com/) color. *(Also changes the default tire smoke color)*

  - **Burnout Smoke:**
    - Same as **Drift Smoke** but for burnouts.

  - Enabling **Pops & Bangs** and **Louder Pops** together makes nearby NPCs react to your exhaust pops. Some will flee, some will insult you, some will be utterly confused, and others will take a picture of your car.

  - **Drift Minigame:**
    - When this option is enabled, drifting your car gives you points which when banked, 10% of them are converted into cash (currently the cashout feature is for Single Player only). You also get bonus points for destroying objects (fences, road signs, road cones, etc...), hitting pedestrians, and jumping in the air. *(PS: if you don't land on all four wheels after a jump, you will lose your points. I will probably rewrite this to make you lose your multiplier instead but as of now, jumping is risky)*.
    - Your highest score will be saved and displayed in the UI.

      > **NOTE:** To bank your points, stop drifting by either driving normally or completely stopping your vehicle. There will be a short 3 second delay in case you want to go back to drifting again but note that if you crash your car into another vehicle or an indestructible object (building, ground, tree, wall...) you will lose all your points.

  - **Missile Defence:**
    - When enabled, all missiles and explosives near your vehicle will be destroyed before they hit you. If a projectile is too close *(that includes missiles, sticky bombs, RPGs or any explosives fired by you from or near your vehicle)*, the denfece will silently remove it instead of exploding it in your face. (the point here is to protect you, not cause you to kill yourself by accident 😅)

  - **Instant 180°:**
    - Press **[Mouse Scroll Down]** or **[Numpad -]** to instantly turn your car 180 degrees. Note that if your car is stopped or moving but you were not holding **[W]** / accelerating when you pressed the Instant 180° button, your car will simply face the opposite direction but if you press it while holding the accelerator then the option will give you back your speed in the opposite direction.

  - **Flappy Doors:**
    - Just opens and closes your doors in succession.
  
  - **Strong Windows:**
    - Prevents your vehicle's windows from breaking.
  
  - **Vehicle Mines:**
    - Equip any land vehicle with mines. Enable the option then press the button to choose the type of mine you want *(**Spike**, **Slick**, **Kinetic**, **EMP**, **Explosive**)* Once everything is set, while driving a vehicle press the assigned button *(default [N])* to deploy mines.
  
  - **Flares For All:**
    - This option equips any plane or helicopter you fly with unlimited flares. Just use the same counter-measure button you use on your weaponized planes *(default: [E] on keyboard)* to fire flares. And yes, they do work as counter-measures same as the ones in weaponized planes, there's just a 3 second delay between each use to prevent unexpected issues.

  - **Higher Plane Speeds:**
    - Increases the speed limit on planes to 576km/h (the game's max). Just enable the option and the rest will take care of itself.
      > **NOTE:** This option will not do anything unless you're flying high enough, with your landing gear fully retracted, and at a speed of at least 260km/h. If for some reason you want to fly a Cropduster at max speed, fly high enough then nose-dive to hit 260km/h.

      >**NOTE:** Pairing this option with "**Extend World Limits**" from the **World** tab allows you to fly out of the sky box. *(if you wanna meet Jesus)*. Beware though, the camera will stop following you once you go past the sky limit. *(so you can't actually see Jesus after all)*.
  
  - **No Engine Stalling:**
    - When flying planes and holding the brake button, your engine will not shut off.
  
  - **Cobra Maneuver:**
    - While flying a plane *(preferably a jet)*, press the assigned key (default [M]) to perform a [Cobra Maneuver](https://www.youtube.com/shorts/H0X7D3Ga4mo). Press any key during the maneuver to cancel it and take back control of the plane.
  
  - **Cannon Triggerbot:**
    - When using a weaponized plane or heli and having the machine gun selected, it will automatically shoot targets in front of you. Also has the option to only shoot enemies.

  - **Cannon Manual Aim:**
    - Gives you the ability to manually aim and shoot an explosive cannon. The only requirement is to be using an aircraft that has a machine gun (doesn't have to be an explosive MG) and the machine gun is the selected weapon.
    - Also works with **Cannon Triggerbot**: if you manually aim at an entity while having the triggerbot enabled, it will automatically blast it wil explosive MG.

  - **Auto-Pilot:**
    - While flying a plane or a helicopter, open the UI and choose one of the auto-pilot options: **Fly To Waypoint**, **Fly To Objective** or **Random**.

  - **Fake Siren:**
    - Equip any land vehicle with a siren *(except of course, vehicles that already have one)*.

      > **NOTE:** If you use this in Online, your vehicle will appear glitched to other players.

  - **Ejecto Seato Cuz!**
    - Press this button to eject all peds from your vehicle. Currently, this does not work on other players or dead peds.

  - **Better Car Crashes:**
    - Makes car crashes a bit more dangerous in 3 steps:
      1. **Crashing at a speed higher than 70km/h and less than 118km/h:** Shakes the gameplay camera.
      2. **Crashing at a speed higher than 118km/h and less than 162km/h:** Applies damage to the vehicle and everyone inside it.
      3. **Crashing at a speed higher than 162km/h:** Has a very high chance of destroying the engine and killing everyone in the vehicle.

  - **ABS Brake Lights:**
    - Also known as **Brake Force Display** in German vehicles: Flashes your brake lights repeatedly when you apply the brakes at a speed higher than 100km/h, similar to modern sports cars *(Only works on cars that have ABS as standard)*.

  - **Door lock control:**
    - Has 2 main options and one complementary option:
      - Simple button to lock and unlock your vehicle.
      - Automatic Mode: Automatically locks your vehicle when you move away from it and unlocks it when you try to enter it again.
      - Auto-Raise Roof: Choose whether locking your vehicle also raises the convertible roof *(if, of course, your vehicle is a convertible)*.

      > **Note:** The feature only works on cars and trucks.

      > **Note:** If you lock a vehicle (or it gets automatically locked) then switch to a different vehicle, the previous one will be automatically unlocked.

  - **Engine Swap:**
    - Changes the sound of your vehicle's engine and increases its power.

  - **Fast Vehicles:**
    - Increases the top speed of any *land* vehicle you drive.

  - **Speedometer:**
    - **Vehicles: A speedometer and tachometer combo with Gear, ABS, NOS, and ESC indicators:**
      - The speedometer has both a digital and an analog display simultaneously. The analog one adapts to the vehicle's maximum speed.
      - The gear indicator changes depending on the vehicle's class: D for normal drive mode, S for sport.
      - The ABS and ESC indicators will not flash if the vehicle doesn't have ABS as standard.
      - The NOS indicator is self explanatory: It lights up when you're using NOS.
    - **Aircraft: When flying planes and helicopters, the speedometer automatically switches modes:**
      - The analog display becomes an altimeter and the RPM gauge becomes a throttle indicator.
      - The speed display in the middle stays the same.
      - The lower indicators show Flares *(from the **Flares For All** feature)* and Landing Gear state.
      - The highest altitude that the altimeter's needle can reach is 2500 meters but there's also an auxiliary text display that shows the exact altitue.

- **Custom Paint Jobs:**
  - Apply a custom paint job to your vehicle from a list of real-life OEM and custom colors.

    > **NOTE:** To save the custom paint job on your personal vehicle, you have to drive into a modshop and buy something.

- **An implementation of [Flatbed Script](https://github.com/xesdoog/Flatbed-Script):**
  - Short explanation: You can tow anything with a flatbed truck. If the vehicle you're towing is occupied, you'll still tow it and kidnap whoever is sitting in it. Note that kidnapping players could sometimes log errors and cause issues *(may even crash your game)*. Also you can't tow players who have protections.

- **Handling Editor:**
  - A tab with a few options that change your vehicle's handling behavior like for example disabling the engine brake (I hate it with a passion 😡) and allowing motorcycles to lose traction so you can drift them. This has been a thorn in my side for longer than I would like to admit. Thanks to [tupoy-ya](https://github.com/tupoy-ya) for helping me finally figure it out.

## Online

- **YimResupplier V3**
  - An improved version of [YimResupplier](https://github.com/YimMenu-Lua/YimResupplier) with a few more options and a redesigned UI.

- **Casino Pacino**
  - An implementation of gir489's [Casino Pacino](https://github.com/YimMenu-Lua/Casino-Pacino), as per their request, with translation support and a slightly altered UI.

- ~**Players:**~
  - ~For now this only displays information about players (money, health, coordinates, vehicle...). I don't know what I'm going to do here since Vehicle Gifting was patched and I don't like nor write toxic features and money drops so unless I can figure out something that can be used to help other players, this will be removed.~

## World

- **Main World Tab:**

  - **Ped Grabber:**
    - Get close to an NPC then press **[LEFT MOUSE BUTTON]** to grab them. Once grabbed, press and hold **[RIGHT MOUSE BUTTON]** then press **[LEFT MOUSE BUTTON]** to throw them. You can change the throwing force using a slider in the UI.

      > NOTE 1: You have to be unarmed to be able to grab an NPC.

      > NOTE 2: While this option is enabled, you will not be able to use your fists (punch). You can still use all other weapons normally until you grab an NPC, then you will not be able to use any weapons until you throw the ped.

    - **[Test Phase Example](https://github.com/user-attachments/assets/378b2084-5d0c-4e24-8557-bbb82d5697e2)**

  - **Vehicle Grabber:**
    - Same as **'Ped Grabber'** but with vehicles.

  - **Ride With NPCs:**
    - When enabled, you will no longer be able to jack NPC vehicles but instead, when you press **[F]** you'll get in as a passenger and all NPC passengers will be cool with it.

  - **Animate Nearby NPCs:**
    - Activate the option then choose an action from the drop down list and press **Play** to make all nearby NPCs play it.

  - **Kamikaze Drivers:**
    - Turns all nearby NPC drivers into suicidal maniacs. Good luck trying to cross the road on foot.

  - **Public Enemy N°1:**
    - Makes all nearby NPCs attack you *(except cops)*.

  - **Extend World Limits:**
    - Allows you to travel farther into the ocean without you dying or your vehicle getting destroyed. Useful if you want to have dogfights in the middle of nowhere. Please note that this does not remove the sky box. You'll still be limited as to how high you can fly.

  - **Smooth Waters:**
    - Gets rid of ocean waves and makes sailing boats or riding jetskis feel like skiing.

  - **Public Seating:**
    - Allows you to sit down on public seats, chairs and benches found in the open world. While free roaming, approach a seat *(there are a bunch of them near Vespucci Beach)*, then when prompted, press **[E]** to sit down. You can sit up by pressing **[E]** again, aiming a weapon, or pressing **[B]** if you have the **Hands Up** feature enabled.
  
  - **Ambient Scenarios:**
    - Allows you to play ambient scenarios that are scattered around in the open world, just like NPCs. These scenarios include taking photos, drinkig, smoking, working out, sitting on benches, chairs, sun loungers, etc...
    These ambient scenarios have exact points on the map where they can be triggered. Once you are in the vicinity of one, a prompt will show up on your screen asking you to press **[E]** to play the scenario.
    > **NOTE:** Because it makes no sense to mark all of them, I'll leave them to your exploration sense to find them.

    > **NOTE:** Due to a few scenarios being in very close proximity to each other, the prompt to play them can become annoying. For this, I've added an option to disable the prompt (but you'll never know when you're near an ambient scenario).

    > **NOTE:** Some ambient scenarios are programmed for NPCs to spawn directly onto them so playing them normally will most likely result in your ped being in an awkward position *(example: sitting in the air)* or even fail to fully play. For this, I've added an option to **force** play or stop an ambient scenario by pressing **[Left Shift]** + **[E]**.

- **EntityForge:**
  - A powerful object/vehicle/ped spawner and creator:
    - Spawn and attach entities (peds, vehicles, objects) to other entities, including yourself.
    - Add object/vehicle/ped models to `Favorites` with custom names.
    - Save whatever abomination you end up creating and spawn it at any time in the future.
    - Add scenario tasks to ped entities before saving them in an attachment.
    - Customize ped entities (clothing, appearance...).
    - Grab entities from the game wrorld using an `Entity Gun`
    - Save models from world entities to `Favorites` and rename/spawn them later.
    - Move and rotate entities in real time using mouse and keyboard.
    - Attached peds automatically play the saved scenario when spawned in a "forged creation".
    - Attached vehicles preserve whatever modifications and colors they had before they were saved.
    - Entities in the `Forge` are **invincible** until removed/dismissed/detached.
  
- **Billionaire Services V2:**
  - [Billionare Services](https://github.com/YimMenu-Lua/Billionare-Services) rewritten from scratch:
    - Spawn as many bodyguards and escort Groups as you want *(the script still limits the total number of entities you can spawn in all features)*.
    - More intuitive UI.
    - Removed childish and offensive options.
    - Removed some of the old Escort Group options (burnouts, donuts, driveby shootings, shouting insults) to make escort groups feel more professional and lore-friendly.
    - Removed LEO escort groups.
    - The ability to add your own custom Escort Groups and save/load them will be added in the future. Don't know when, I'm too tired of this.
    - Private Jets are limited to only 2 models: **Nimbus** and **Luxor Deluxe**. The rest are broken *(yes, I tested all of them)*.
    - Added a couple more limousine models with custom paint jobs and modifications.
    - All peds in this script no longer use the player's group and rely on the game to handle group behavior. It now has its own custom group manager.
    - When you have bodyguards around and get in a vehicle, those who manage to find a free seat will enter your vehicle while the rest will first try to jack a nearby vehicle and if that fails, they will spawn their own crotch rocket (Bati 801) and follow you. Please note that this process may take a few seconds depending on how many bodyguards you have *(they don't all think or react at the same time to prevent killing your FPS)*.

## Settings

- Here you can enable/disable tooltips, enable/disable sound feedback from UI interactions, enable/disable ambient flight music, delete the custom animation hotkey, change the script's language, and reset all saved options (except created vehicles and outfits).

## Hotkeys

- Here you can set or change keyboard and controller keybinds.

## Command Executor

- Allows you to execute a few commands on the fly. Wanna quickly full up your hangar? Open the Command Executor by pressing the assigned button and type: `autofill.hangar`.
- **Default Buttons:**
  - **Open:** **[NUMPAD7]** (can be changed in the **Hotkeys** tab).
  - **Close:** **[ESC]** (hardcoded).

- **Full list of commands:**.
  - `autoheal` : Enables/Disables the script's auto-heal feature.
  - `rod` : Enables/Disables the **Ragdoll On Demand** feature.
  - `autofill.hangar` : Starts auto-filling your hangar cargo.
  - `autofill.whouse1` : Starts auto-filling your CEO Warehouse N°1 *(if you have more than one, use the same command with the corresponding number. Ex: `autofill.whouse4`)*.
  - `yrv2.fillall` : Fills all your owned businesses with supplies.
  - `finishsale` : Instantly finishes a sale mission (from a list of missions supported by the script). Will be skipped if you have the **Auto-Sell** option enabled.
  - `fastvehs` : Increases the top speed of any *land* vehicle you drive.
  - `spawnmeaperv` : No comment.
  - `kys` : Kills you.
  - `vehlock` : Locks/unlocks your vehicle.
  - `PANIK` : Resets all changes done by the script (same as the panic button).
  - `resetcfg` : Resets the script and restores your saved config to default.

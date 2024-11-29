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

- **Actions:**

  - **An improved version of [YimActions](https://github.com/xesdoog/YimActions) with the side features moved into the main Self tab. The improvements include:**
    - The ability to sort animations by category.
    - The ability to set a custom shortcut key for a specific animation so that you could play it any time you want.
    - Some animations produce sound (Sleeping, Crying, DJ *(plays loud music)*, some uh... uhm, NSFW animations also play sounds).
    - An option to browse and play animations using hotkeys. This option may interfere with gameplay so you can enable/disable it any time you want.
    - New **Favorites** tab:
      - Save animations and scenarios to favorites then play them from this tab (they will persist even if you reset your config from the **Settings** tab).
    - New **Recently Played** tab:
      - A new tab that shows recently played animations and scenarios and allows you to play/stop them from there.

- **Sound Player:**
  - Plays either human speeches or loud radio music that players nearby can hear (assuming you're not lagging and there are no sync issues).

## Weapon

- **Info Gun:**
  - A debug option that will be removed in the future. Simply aim your gun at a game entity and press **[Left Mouse Button]** to log information about it to the console.

- **Trigger Bot:**
  - A barebones and janky triggerbot. *Kinda works?* Only on foot though.

- **Autokill Enemies:**
  - Automatically kills nearby enemies and destroys their vehicle if they are inside one.

- **Enemies Flee:**
  - All nearby enemies will drop their weapons and run away from you. Note that during some missions, enemies will be confused and sometimes stand still and scream in horror because the game is forcing them to attack and this script is forcing them to flee.

- **Katana:**
  - Replaces the *Machete* weapon with a Japanese katana. If you don't own a Machete, you can either buy one from Ammu-Nation or use YimMenu to equip a temporary one. Once you have one equipped in your hands, it will be automatically replaced with a Katana.

- **Laser Sight:**
  - Renders a laser sight on your weapons when you're aiming them. You can choose between Red, Green, and Blue lasers. Can be toggled on/off by pressing the assigned key *(default **[L]** on keyboard)*.

## Vehicle

- **All features from [TokyoDrift](https://github.com/YimMenu-Lua/TokyoDrift) with a few improvements and additions:**

  - **Better Drift Mode / Drift Tires:**
    - Increased torque while drifting so that you could pick up speed faster and hold bigger angles. You can choose how much toruqe you want to gain.

  - **Drift Smoke:**
    - Your tires will now produce a lot more smoke when drifting. The smoke will appear when you're drifting at a speed higher than *approx: 15mph // 20km/h*. You can change the smoke color either from a drop down list of pre-defined colors or by inputting your own [HEX](https://www.color-hex.com/) color. Note that the drift smoke color has no relation to your actual tire smoke color but I can change that if desired, it's just one line of code.

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

  - **Flares For All:**
    - This option equips any plane or helicopter you fly with unlimited flares. Just use the same counter-measure button you use on your weaponized planes *(default: [E] on keyboard)* to fire flares. And yes, they do work as counter-measures same as the ones in weaponized planes, there's just a 3 second delay between each use to prevent unexpected issues.

  - **Higher Plane Speeds:**
    - Increases the speed limit on planes to 555km/h. Just enable the option and the rest will take care of itself.
      > **NOTE:** This option will not do anything unless you're flying high enough, with your landing gear fully retracted, and at a speed of at least 260km/h. If for some reason you want to fly a Cropduster at 555km/h, fly high enough then nose-dive to hit 260km/h.
  
  - **Vehicle Mines:**
    - Equip any land vehicle with mines. Enable the option then press the button to choose the type of mine you want *(Spike, Slick, Kinetic, EMP, Explosive)* Once everything is set, while driving a vehicle press the **Push To Talk** button *(default [N])* to deploy mines.

  - **Auto-Pilot:**
    - While flying a plane or a helicopter, open the UI and choose one of the auto-pilot options: Fly To Waypoint, Fly To Objective or Fly to random coordinates.
  
  - **Fake Siren:**
    - Equip any land vehicle with a siren *(except of course, vehicles that already have one)*.

      > **NOTE:** If you use this in Online, your vehicle will appear glitched to other players.

  - **Ejecto Seato Cuz!**
    - Press this button to eject all peds from your vehicle. Currently, this does not work on other players.
  
  - **Dangerous Car Crashes:**
    - Makes car crashes a bit more dangerous in 3 steps:
      1. **Crashing at a speed higher than 70km/h and less than 118km/h:** Shakes the gameplay camera.
      2. **Crashing at a speed higher than 118km/h and less than 162km/h:** Applies damage to the vehicle and everyone inside it.
      3. **Crashing at a speed higher than 162km/h:** Has a very high chance of destroying the engine and killing everyone in the vehicle.

- **Custom Paint Jobs:**
  - Apply a custom paint job to your vehicle from a list of real-life OEM and custom colors.

    > **NOTE:** To save the custom paint job on your personal vehicle, you have to drive into a modshop and buy something.

- **An implementation of [Flatbed Script](https://github.com/xesdoog/Flatbed-Script):**
  - Short explanation: You can tow anything with a flatbed truck. If the vehicle you're towing is occupied, you'll still tow it and kidnap whoever is sitting in it. Note that kidnapping players could sometimes log errors and cause issues *(may even crash your game)*. Also you can't tow players who have protections.

- **Handling Editor:**
  - A tab with a few options that change your vehicle's handling behavior like for example disabling the engine brake (I hate it with a passion 😡) and allowing motorcycles to lose traction so you can drift them. This has been a thorn in my side for longer than I would like to admit. Thanks to [tupoy-ya](https://github.com/tupoy-ya) for helping me finally figure it out.

- **Vehicle Creator:**
  - Spawn and merge two or more vehicles into one then save it as a custom vehicle. Wanna create a widebody Futo? A Sentinel XS with 2 BMXs on the roof? A driveable skyscraper made out of tanks? Feel free.

## Online

- **Business Manager**
  - An improved version of [YimResupplier](https://github.com/YimMenu-Lua/YimResupplier) with a few more options and a redesigned UI.

- **Casino Pacino**
  - An implementation of gir489's [Casino Pacino](https://github.com/YimMenu-Lua/Casino-Pacino) with translation support and a slightly altered UI.

- **Players:**
  - For now this only displays information about players (money, health, coordinates, vehicle...). I don't know what I'm going to do here since Vehicle Gifting was patched and I don't like nor write toxic features and money drops so unless I can figure out something that can be used to help other players, this will be removed.

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
    - Activate the option then choose an action from the drop down list and press **Play** to make all nearby NPCs do that action.

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

- **Improved [Object Spawner](https://github.com/xesdoog/object-spawner):**
  - Fixed a few bugs in the main script and added the ability to attach objects to your vehicle.
  - Added an option to save self attachments. This gives you the ability to create outfits for yourself made out of objects then spawn them at any time in the future.

## Settings

- Here you can enable/disable tooltips, enable/disable sound feedback from UI interactions, enable/disable ambient flight music, delete the custom animation hotkey, change the script's language, and reset all saved options (except created vehicles and outfits).

## Hotkeys

- Here you can set or change keyboard and controller keybinds.

## Self
- **Main Self Features:**
  - **Auto-Heal:**
    - Constantly fills your health and armour whenever they fall below the maximum.
  - **Teleport To Objective:**
    - This was only added because the option in YimMenu was kind of broken. [gir489returns](https://github.com/gir489returns) fixed it so this one will be removed.
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

- **Actions:**
  - **An improved version of [YimActions](https://github.com/xesdoog/YimActions) with the side features moved into the main Self tab. The improvements include:**
    - The ability to set a custom shortcut key for a specific animation so that you could play it any time you want. I have mine set as **[L]** to play a hitch-hike animation.
    - Some animations produce sound (Sleeping, Crying, DJ *(plays loud music)*, some uh.. uhm, NSFW animations also play sounds).
    - An option to browse and play animations using hotkeys. This option may interfere with gameplay so you can enable/disable it any time you want.

- **Sound Player:**
  - Plays either human speeches or loud radio music that players nearby can hear (assuming you're not lagging and there are no sync issues).

## Weapon
- **Info Gun:**
  - A debug option that will be removed in the future. Simply aim your gun at a game entity and press [Left Mouse Button] to log information about it to the console.
- **Trigger Bot:**
  - ~A barebones and janky triggerbot. *Kinda works?* Only on foot though. Will probably be removed once YimMenu's triggerbot gets fixed.~ [gir489returns](https://github.com/gir489returns) also fixed YimMenu's triggerbot. There's no need for this feature anymore.
- **Autokill Enemies:**
  - Automatically kills nearby enemies. I've put a delay to prevent kill spamming because I don't want enemies to die the moment they spawn. Feedback on this would be appreciated *(keep the delay or spam kill?)*.
- **Enemies Flee:**
  - All enemies nearby will drop their weapons and run away from you. Note that during some missions, enemies will be confused and sometimes stand still and scream in horror because the game is forcing them to attack and this script is forcing them to flee.
- **Laser Sight:**
  - Renders a laser sight on your weapons when you're aiming them. The laser doesn't look perfect and doesn't travel far either. You can choose between red and green lasers.

## Vehicle:
- **All features from [TokyoDrift](https://github.com/YimMenu-Lua/TokyoDrift) with a few improvements and additions:**
  - **Better Drift Mode / Drift Tires:**
    - Increased torque while drifting so that you could pick up speed faster while drifting and hold bigger angles.
  - **Drift Smoke:**
    - Your tires will now produce a lot more smoke when drifting. The smoke will appear when you're drifting at a speed higher than *approx: 15mph // 20km/h*. You can change the smoke color either from a drop down list of pre-defined colors or inputting your own [HEX](https://www.color-hex.com/) color. Note that the drift smoke color has no relation to your actual tire smoke color but I can change that if desired, it's just one line of code.
  - **Drift Minigame:**
    - When this option is enabled, drifting your car gives you points which when banked, 10% of them are converted into cash (currently the cashout feature is for Single Player only). You also get bonus points for destroying objects (fences, road signs, road cones, etc...), hitting pedestrians, and jumping in the air. *(PS: if you don't land on all four wheels after a jump, you will lose your points. I will probably rewrite this to make you lose your multiplier instead but as of now, jumping is risky)*.
      
      > NOTE: To bank your points, stop drifting by either driving normally or completely stopping your vehicle. There will be a short 3 second delay in case you want to go back to drifting again but note that if you crash your car into another vehicle or an indestructible object (building, ground, tree, wall...) you will lose all your points.

  - **Missile Defense:**
    - When enabled, all missiles and explosives near your vehicle will be destroyed before they hit you. If a projectile is too close *(that includes missiles, sticky bombs, RPGs or any explosives fired by you from or near your vehicle)*, the denfese will silently remove it instead of exploding it in your face. (the point here is to protect you, not cause you to kill yourself by accident 😅)
      
  - **Instant 180°:**
    - Press **[Mouse Scroll Down]** or **[Numpad -]** to instantly turn your car 180 degrees. Note that if your car is stopped or moving but you were not holding **[W]** / accelerating when you pressed the Instant 180° button, your car will simply face the opposite direction but if you press it while holding the accelerator then the option will give you back your speed in the opposite direction.
  - **Flappy Doors:**
    - Just opens and closes your doors in succession. It's all about the rhythm the doors opening and closing produce.
  - **Fake Siren:**
    - Equip any land vehicle with a siren *(except of course, vehicles that already have one)*.

- **An implementation of [Flatbed Script](https://github.com/xesdoog/Flatbed-Script):**
  - Short explanation: You can tow anything with a flatbed truck. If the vehicle you're towing is occupied, you'll still tow it and kidnap whoever is sitting in it. Note that kidnapping players could sometimes log errors and cause issues. Also you can't tow players who have protections.
 
- **Vehicle Creator:**
  - Spawn and merge two or more vehicles into one then save it as a custom vehicle. Wanna create a widebody Futo? A Sentinel XS with 2 BMXs on the roof? A drivable skyscraper made out of tanks? Feel free.


## Players
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
    - When enabled, you will not be able to jack NPC vehicles but instead when you press **[F]** you will get in as a passenger and the driver NPC will be cool with it. *The passengers will be confused and frightened though...*
  - **Animate Nearby NPCs:**
    - Activate the option then choose an action from the drop down list and press **Play** to make all nearby NPCs do that action.

  - **Kamikaze Drivers:**
    - All nearby drivers will be turned into suicidal maniacs. Good luck trying to cross the road on foot.
   
  - **Public Enemy N°1:**
    - When enabled, all nearby NPCs will attack you *(except cops)*.
      
- **Improved [Object Spawner](https://github.com/xesdoog/object-spawner):**
  - Fixed a few bugs in the main script and added the ability to attach objects to your vehicle.

## Settings
- Here you can enable/disable tooltips, enable/disable sound feedback from UI interactions, delete the custom animation hotkey, change the script's language, and reset all saved options.

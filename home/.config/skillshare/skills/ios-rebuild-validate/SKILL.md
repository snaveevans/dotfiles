---
name: ios-rebuild-validate
description: Rebuilds and validates iOS app after code changes. Compiles, installs, launches in simulator, monitors logs. Escalates from fast build to clean build on failure. Ensures every task ends with a running app.
---

# iOS Rebuild & Validate

## Safe defaults

- Always rebuild before validating any UI change
- Use iPhone 16e simulator (or get booted simulator ID)
- Bundle ID: com.tatooine.app (configurable)
- DerivedData path: ~/Library/Developer/Xcode/DerivedData/Tatooine-*/

## Workflow

### Step 1: Compile the project

Run xcodebuild for the current scheme:
```
xcodebuild -project Tatooine.xcodeproj -scheme Tatooine -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16e' build
```

Check output for `BUILD SUCCEEDED`. If build fails, stop here - do not proceed to install.

### Step 2: Escalate on failure

If build fails:
1. First retry: Clean DerivedData and rebuild
2. Second retry: Delete app from simulator, rebuild, reinstall
3. Third retry: Full reset - shutdown simulator, boot fresh, rebuild

### Step 3: Install on simulator

Get booted simulator UDID:
```
ios-simulator_get_booted_sim_id
```

Install the built app:
```
ios-simulator_install_app app_path=<DerivedData path> udid=<simulator UDID>
```

### Step 4: Launch and validate

Launch the app:
```
ios-simulator_launch_app bundle_id=com.tatooine.app terminate_running=true udid=<simulator UDID>
```

Take screenshot to verify:
```
ios-simulator_screenshot output_path=./screenshot.png udid=<simulator UDID>
```

## Validation

- [ ] Build shows `BUILD SUCCEEDED`
- [ ] App installs without error
- [ ] App launches successfully
- [ ] Screenshot captured

## Failure modes

- **No booted simulator**: Use `ios-simulator_open_simulator` first
- **Build fails**: Clean DerivedData, check for code errors
- **Install fails**: Uninstall existing app first, ensure simulator is booted
- **Launch fails**: Check bundle ID matches Info.plist

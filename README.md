# Cobrowse.io - Example iOS App

Cobrowse.io is 100% free and easy to try out in your own apps. Please see full documentation at [https://docs.cobrowse.io](https://docs.cobrowse.io).

You can try our online demo at [https://cobrowse.io/demo](https://cobrowse.io/demo).

## Building

Open `Cobrowse.xcodeproj`

This example project uses Swift Package Manager to pull in the Cobrowse iOS SDK and other dependencies. All dependencies are public and should checkout without the need to authenticate Xcode.

With the Cobrowse target selected run the project.

If building to device please update the Team ID, bundle ID. If manually provisioning please set them in the Signing & Capabilities tab of both the main App target and the Extension target.

*Note full device mode will only work on a real device. Full device mode is **not** supported in the simulator.*

## Add your license key

Once you have an account you can locate your license key at [https://cobrowse.io/dashboard/settings](https://cobrowse.io/dashboard/settings).

Copy your license key, open up [AppDelegate.swift](https://github.com/cobrowseio/cobrowse-sdk-ios-examples/blob/master/Cobrowse/AppDelegate.swift) and replace `trial` with your license key.

```swift
cobrowse.license = "trial"
```

## Try it out

Once you have the app running in the simulator or on a physical device, navigate to [https://cobrowse.io/dashboard](https://cobrowse.io/dashboard) to see your device listed. You can click the **Connect** button to start a Cobrowse session.

## Questions?

Any questions at all? Please email us directly at [hello@cobrowse.io](mailto:hello@cobrowse.io).

## Requirements

iOS 16+

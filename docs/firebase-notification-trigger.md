# Firebase notification trigger guide

How to click through the Firebase console and send a notification to the liaison officer Android app. This file is the console steps only. Who stores the device token and who sends when a delegate is assigned on the web is in [delegate-assignment-notification.md](delegate-assignment-notification.md).

Console: [Messaging campaigns](https://console.firebase.google.com/u/0/project/lo-mobile-app/messaging), signed in as `punithsuppar7795@gmail.com`.

Project: `lo-mobile-app`. Android app: Liaison Officer (`com.bel.liaison_officer`).

A live send is already on the Campaigns tab: **Delegate assigned / Asha Rao**, status Active, started 1 Oct 2026 09:46:40, target Android.

## 1.0.7 already has FCM on

The release workflow builds `releases/liaison-officer-1.0.7.apk` with `--dart-define=ENABLE_FCM=true` (see `.github/workflows/build-release-apk.yml`). That APK can receive a console campaign. Do not cut a 1.0.8 build just to turn FCM on.

FCM stays off only in a build that omits that define. The installed 1.0.7 release is not that build.

## Send now

This is the click that sends. It reaches every install of the Android app, including 1.0.7. It does not pick one officer by email.

1. Open [Messaging](https://console.firebase.google.com/u/0/project/lo-mobile-app/messaging).
2. **New campaign**, then **Notifications** (Firebase Notification messages).
3. Notification title: `Delegate assigned`. Notification text: a delegate name, for example `Asha Rao`.
4. **Next**.
5. Target: **User segment**. App: **Liaison Officer** (`com.bel.liaison_officer`). **Next**.
6. Scheduling: leave **Send now**. **Next**.
7. Key events: leave empty. **Next**.
8. Additional options (step 5): under **Custom data**, key `link`, value `delegate:123`.
9. **Review**, then **Publish**.

After publish the row appears on Campaigns with status Active (or Completed once Firebase finishes). Sends are shown as a bucket such as `<1,000`, not as a named officer.

## Send to one phone

On the Notification step, **Send test message**. Paste one FCM registration token, then **Test**. That does not publish the campaign.

The installed 1.0.7 APK does not print the token. A debug build with `ENABLE_FCM=true` prints one line when the phone is signed in and connected over USB:

```text
FcmDeviceRegistrar: fcmToken ...
```

That print is in `lib/core/services/fcm_device_registrar.dart` and runs only in debug mode. Copy the token from logcat into **Send test message**. With no USB phone, the token box stays empty and **Test** stays disabled.

The portal register call can stay a 404. The console test uses the token directly and does not need a service-account key.

## Schedule a time

Use the same composer. On the Scheduling step, do not leave **Send now**.

### Once, at a clock time

Choose **Scheduled**. Pick the date and time. **Review**, then **Publish**. The campaign stays scheduled until that time, then Firebase sends it.

### Daily, or a custom repeat

Set the clock time and the start and end dates, then **Publish**. This project shows `0/10` recurring notifications, so at most 10 recurring campaigns can be active at once.

Leave the time zone as the console default unless a save error appears. Recipient time zone needs the start date at least one day ahead.

## On the phone

1.0.7 must have been opened once after install, with notifications allowed. Put the app in the background. The tray shows the title (`Delegate assigned`).

A tap reads `data.link` in `lib/features/liaison_officer/presentation/shells/lo_portal_shell.dart`:

- a link containing `delegate` opens the Delegates tab
- a link containing `task` opens the Tasks tab

`link` = `delegate:123` opens Delegates. This PC cannot see the phone, so confirm the tray on the device.

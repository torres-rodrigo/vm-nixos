# Fingerprint Scanner

## Current Policy

`conquest` has enrollment-only fingerprint support through `fprintd`.

The detected scanner is:

```text
27c6:63ac Shenzhen Goodix Technology Co.,Ltd. Goodix Fingerprint USB Device
```

This USB ID is listed by libfprint as a supported Goodix MOC fingerprint sensor,
but support still needs to be validated on the real laptop.

The current scope is:

- enable `fprintd` through `services.fprintd.enable = true`;
- test enrollment and verification from a terminal;
- keep login, greetd, sudo, polkit, and screen unlock password-only for now;
- defer PAM integration until enrollment and verification are reliable.

## Enrollment

After building and activating the `conquest` configuration, enroll a fingerprint
for user `r`:

```console
fprintd-enroll r
```

Verify the enrolled fingerprint:

```console
fprintd-verify r
```

List enrolled fingerprints:

```console
fprintd-list r
```

Delete enrolled fingerprints if testing needs to start over:

```console
fprintd-delete r
```

## Authentication

Do not enable fingerprint authentication for PAM services yet.

This means:

- sudo still requires the user password;
- greetd and TTY login still require the user password;
- polkit prompts still require the user password;
- screen unlock remains password-based until a locker is chosen and tested.

This is intentional. A fingerprint reader should not become part of the auth
path until the device can enroll and verify consistently after boot, suspend,
resume, and replug-style USB resets.

## Validation

After activation on `conquest`:

```console
systemctl status fprintd
fprintd-enroll r
fprintd-verify r
fprintd-list r
journalctl -b -u fprintd --no-pager
```

Expected result:

- `fprintd` starts successfully;
- the Goodix `27c6:63ac` sensor is detected;
- enrollment completes for user `r`;
- verification succeeds repeatedly;
- login and sudo remain password-only.

If enrollment reports no device or verification fails repeatedly, keep the
module disabled or leave it enrollment-only while investigating libfprint
support for this specific sensor and firmware.

## References

- libfprint supported devices:
  <https://fprint.freedesktop.org/supported-devices.html>
- fprint project and fprintd overview:
  <https://fprint.freedesktop.org/>

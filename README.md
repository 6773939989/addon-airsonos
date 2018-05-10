# Community Hass.io Add-ons: AirSonos

[![GitHub Release][releases-shield]][releases]
![Project Stage][project-stage-shield]
![Project Maintenance][maintenance-shield]
[![GitHub Activity][commits-shield]][commits]
[![License][license-shield]](LICENSE.md)

[![CircleCI][circleci-shield]][circleci]
[![Bountysource][bountysource-shield]][bountysource]
[![Discord][discord-shield]][discord]
[![Community Forum][forum-shield]][forum]

[![Patreon][patreon-shield]][patreon]
[![PayPal][paypal-shield]][paypal]
[![Bitcoin][bitcoin-shield]][bitcoin]

AirPlay capabilities for your Sonos (and UPnP) players.

## About

Apple devices use AirPlay to send audio to other devices, but this is not
compatible with Sonos players. This add-on tries to solve this
compatibility gap.

It detects Sonos players in your network and creates virtual AirPlay
devices for each of them. It acts as a bridge between the AirPlay client
and the real Sonos device.

Since Sonos uses UPnP, the add-on might also work for other UPnP players
(e.g., newer Samsung televisions).

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add our Hass.io add-ons repository][repository] to your Hass.io instance.
1. Install the "AirSonos" add-on.
1. Start the "AirSonos" add-on
1. Check the logs of the "AirSonos" add-on to see if everything went well.

After ~30 seconds you should see some log messages appear in the add-on log.
Using your iOS/Mac/iTunes/Airfoil/other clients, you should now see new AirPlay
devices and can try to play audio to them.

**NOTE**: Do not add this repository to Hass.io, please use:
`https://github.com/hassio-addons/repository`.

## Docker status

[![Docker Architecture][armhf-arch-shield]][armhf-dockerhub]
[![Docker Version][armhf-version-shield]][armhf-microbadger]
[![Docker Layers][armhf-layers-shield]][armhf-microbadger]
[![Docker Pulls][armhf-pulls-shield]][armhf-dockerhub]

[![Docker Architecture][aarch64-arch-shield]][aarch64-dockerhub]
[![Docker Version][aarch64-version-shield]][aarch64-microbadger]
[![Docker Layers][aarch64-layers-shield]][aarch64-microbadger]
[![Docker Pulls][aarch64-pulls-shield]][aarch64-dockerhub]

[![Docker Architecture][amd64-arch-shield]][amd64-dockerhub]
[![Docker Version][amd64-version-shield]][amd64-microbadger]
[![Docker Layers][amd64-layers-shield]][amd64-microbadger]
[![Docker Pulls][amd64-pulls-shield]][amd64-dockerhub]

[![Docker Architecture][i386-arch-shield]][i386-dockerhub]
[![Docker Version][i386-version-shield]][i386-microbadger]
[![Docker Layers][i386-layers-shield]][i386-microbadger]
[![Docker Pulls][i386-pulls-shield]][i386-dockerhub]

## Configuration

**Note**: _Remember to restart the add-on when the configuration is changed._

Example add-on configuration:

```json
{
  "log_level": "info",
  "address": "192.168.1.234",
  "port": 49152,
  "latency_rtp": 1000,
  "latency_http": 2000,
  "drift": true
}
```

**Note**: _This is just an example, don't copy and past it! Create your own!_

### Option: `log_level`

The `log_level` option controls the level of log output by the addon and can
be changed to be more or less verbose, which might be useful when you are
dealing with an unknown issue. Possible values are:

- `trace`: Show every detail, like all called internal functions.
- `debug`: Shows detailed debug information.
- `info`: Normal (usually) interesting events.
- `warning`: Exceptional occurrences that are not errors.
- `error`:  Runtime errors that do not require immediate action.
- `fatal`: Something went terribly wrong. Add-on becomes unusable.

Please note that each level automatically includes log messages from a
more severe level, e.g., `debug` also shows `info` messages. By default,
the `log_level` is set to `info`, which is the recommended setting unless
you are troubleshooting.

These log level also affects the log levels of AirSonos server.

### Option: `address`

This option allows you to specify the IP address the AirSonos server needs to
bind to. It will automatically detect the interface to use when this option is
left empty. Nevertheless, it might get detected wrong (e.g., in case you have
multiple network interfaces).

### Option: `port`

The port the AirSonos server will expose itself on. The default `49152` should
be fine in most cases. Only change this if you really have to.

### Option: `latency_rtp`

Allows you to tweak the buffering, which is needed when the audio is stuttering
(e.g., low-quality network). This option specifies the number of ms the addon
has to buffer the RTP audio (AirPlay). Setting this value below 500ms is not
recommended!

### Option: `latency_http`

Allows you to tweak the buffering, which is needed when the audio is stuttering
(e.g., low-quality network). This option specifies the number of ms the addon
has to buffer the HTTP audio.

### Option: `drift`

Set to `true` to let timing reference drift (no click).

## Sonos hints and limitations

When a Sonos group is created, only the master of that group will appear as
an AirPlay player and others will be removed if they were already detected.
If the group is later split, then individual players will re-appear.
Each detection cycle takes ~30 seconds.

Volume is set for the whole group, but the same level applies to all members.
If you need to change individual volumes, you need to use a Sonos native
controller. **Note**: these will be overridden if the group volume is later
changed again from an AirPlay device.

## Latency options explained

These bridges receive real-time "synchronous" audio from the AirPlay controller
in the format of RTP frames and forward it to the Sonos player in an HTTP
"asynchronous" continuous audio binary format. In other words,
the AirPlay clients "push" the audio using RTP and the Sonos players
"pull" the audio using an HTTP GET request.

A player using HTTP to get its audio expects to receive an initial large
portion of audio as the response to its GET and this creates a large enough
buffer to handle most further network congestion/delays. The rest of the audio
transmission is regulated by the player using TCP flow control. However, when
the source is an AirPlay RTP device, there is no such significant portion of
audio available in advance to be sent to the Player, as the audio comes to the
bridge in real time. Every 8ms, an RTP frame is received and is immediately
forwarded as the continuation of the HTTP body. If the Sonos player
starts to play immediately the first received audio sample, expecting an initial
burst to follow, then any network congestion delaying RTP audio will starve
the player and create shuttering.

The `latency_http` option allows a certain amount of silence frames to be sent
to the Sonos player, in a burst at the beginning. Then, while this
"artificial" silence is being played, it is possible for the bridge to build
a buffer of RTP frames that will then hide network delays that might happen
in further RTP frames transmission. This delays the start of the playback
by `latency_http` ms.

However, RTP frames are transmitted using UDP, which means there is no guarantee
of delivery, so frames might be lost from time to time
(often happens on WiFi networks). To allow detection of lost frames, they are
numbered sequentially (1,2 ... n) so every time two received frames are not
consecutive, the missing ones can be asked again by the AirPlay receiver.

Typically, the bridge forwards immediately every RTP frame using HTTP and again,
in HTTP, the notion of frame numbers does not exist, it is just the continuous
binary audio. So it is not possible to send audio non-sequentially when using
HTTP.

For example, if received RTP frames are numbered 1,2,3,6, this bridge will
forward (once decoded and transformed into raw audio) 1,2,3 immediately using
HTTP but when it receives 6, it will re-ask for 4 and 5 to be resent and
hold 6 while waiting (if 6 was transmitted immediately, the Sonos
will play 1,2,3,6 ... not nice).

The `latency_rtp` option sets for how long frame 6 shall be held before adding
two silence frames for 4 and 5 and send sending 4,5,6. Obviously, if this delay
is larger than the buffer in the Sonos player, playback will stop by
lack of audio. Note that `latency_rtp` does not delay playback start.

> **Note**: `latency_rtp` and `latency_http` could have been merged into a
single `latency` parameter which would have set the max RTP frames holding time
as well as the duration of the initial additional silence (delay),
however, all Sonos devices do properly their own buffering of HTTP audio
(i.e., they wait until they have received a certain amount of audio before
starting to play), then adding silence would have introduced an extra
unnecessary delay in playback.

## Changelog & Releases

This repository keeps a [change log](CHANGELOG.md). The format of the log
is based on [Keep a Changelog][keepchangelog].

Releases are based on [Semantic Versioning][semver], and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Support

Got questions?

You have several options to get them answered:

- The Home Assistant [Community Forum][forum], we have a
  [dedicated topic][forum] on that forum regarding this add-on.
- The Home Assistant [Discord Chat Server][discord] for general Home Assistant
  discussions and questions.
- Join the [Reddit subreddit][reddit] in [/r/homeassistant][reddit]

You could also [open an issue here][issue] GitHub.

## Contributing

This is an active open-source project. We are always open to people who want to
use the code or contribute to it.

We have set up a separate document containing our
[contribution guidelines](CONTRIBUTING.md).

Thank you for being involved! :heart_eyes:

## Authors & contributors

The original setup of this repository is by [Franck Nijhof][frenck].

For a full list of all authors and contributors,
check [the contributor's page][contributors].

## We have got some Hass.io add-ons for you

Want some more functionality to your Hass.io Home Assistant instance?

We have created multiple add-ons for Hass.io. For a full list, check out
our [GitHub Repository][repository].

## License

MIT License

Copyright (c) 2017 Franck Nijhof

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

[aarch64-arch-shield]: https://img.shields.io/badge/architecture-aarch64-blue.svg
[aarch64-dockerhub]: https://hub.docker.com/r/hassioaddons/airsonos-aarch64
[aarch64-layers-shield]: https://images.microbadger.com/badges/image/hassioaddons/airsonos-aarch64.svg
[aarch64-microbadger]: https://microbadger.com/images/hassioaddons/airsonos-aarch64
[aarch64-pulls-shield]: https://img.shields.io/docker/pulls/hassioaddons/airsonos-aarch64.svg
[aarch64-version-shield]: https://images.microbadger.com/badges/version/hassioaddons/airsonos-aarch64.svg
[amd64-arch-shield]: https://img.shields.io/badge/architecture-amd64-blue.svg
[amd64-dockerhub]: https://hub.docker.com/r/hassioaddons/airsonos-amd64
[amd64-layers-shield]: https://images.microbadger.com/badges/image/hassioaddons/airsonos-amd64.svg
[amd64-microbadger]: https://microbadger.com/images/hassioaddons/airsonos-amd64
[amd64-pulls-shield]: https://img.shields.io/docker/pulls/hassioaddons/airsonos-amd64.svg
[amd64-version-shield]: https://images.microbadger.com/badges/version/hassioaddons/airsonos-amd64.svg
[armhf-arch-shield]: https://img.shields.io/badge/architecture-armhf-blue.svg
[armhf-dockerhub]: https://hub.docker.com/r/hassioaddons/airsonos-armhf
[armhf-layers-shield]: https://images.microbadger.com/badges/image/hassioaddons/airsonos-armhf.svg
[armhf-microbadger]: https://microbadger.com/images/hassioaddons/airsonos-armhf
[armhf-pulls-shield]: https://img.shields.io/docker/pulls/hassioaddons/airsonos-armhf.svg
[armhf-version-shield]: https://images.microbadger.com/badges/version/hassioaddons/airsonos-armhf.svg
[bitcoin-shield]: https://img.shields.io/badge/donate-bitcoin-blue.svg
[bitcoin]: https://blockchain.info/payment_request?address=3GVzgN6NpVtfXnyg5dQnaujtqVTEDBCtAH
[bountysource-shield]: https://img.shields.io/bountysource/team/hassio-addons/activity.svg
[bountysource]: https://www.bountysource.com/teams/hassio-addons/issues
[circleci-shield]: https://img.shields.io/circleci/project/github/hassio-addons/addon-airsonos.svg
[circleci]: https://circleci.com/gh/hassio-addons/addon-airsonos
[commits-shield]: https://img.shields.io/github/commit-activity/y/hassio-addons/addon-airsonos.svg
[commits]: https://github.com/hassio-addons/addon-airsonos/commits/master
[contributors]: https://github.com/hassio-addons/addon-airsonos/graphs/contributors
[discord-shield]: https://img.shields.io/discord/330944238910963714.svg
[discord]: https://discord.gg/c5DvZ4e
[forum-shield]: https://img.shields.io/badge/community-forum-brightgreen.svg
[forum]: https://community.home-assistant.io/t/community-hass-io-add-on-airsonos/36796?u=frenck
[frenck]: https://github.com/frenck
[home-assistant]: https://home-assistant.io
[i386-arch-shield]: https://img.shields.io/badge/architecture-i386-blue.svg
[i386-dockerhub]: https://hub.docker.com/r/hassioaddons/airsonos-i386
[i386-layers-shield]: https://images.microbadger.com/badges/image/hassioaddons/airsonos-i386.svg
[i386-microbadger]: https://microbadger.com/images/hassioaddons/airsonos-i386
[i386-pulls-shield]: https://img.shields.io/docker/pulls/hassioaddons/airsonos-i386.svg
[i386-version-shield]: https://images.microbadger.com/badges/version/hassioaddons/airsonos-i386.svg
[issue]: https://github.com/hassio-addons/addon-airsonos/issues
[keepchangelog]: http://keepachangelog.com/en/1.0.0/
[license-shield]: https://img.shields.io/github/license/hassio-addons/addon-airsonos.svg
[maintenance-shield]: https://img.shields.io/maintenance/yes/2018.svg
[patreon-shield]: https://img.shields.io/badge/donate-patreon-blue.svg
[patreon]: https://www.patreon.com/frenck
[paypal-shield]: https://img.shields.io/badge/donate-paypal-blue.svg
[paypal]: https://www.paypal.me/FranckNijhof
[project-stage-shield]: https://img.shields.io/badge/project%20stage-experimental-yellow.svg
[reddit]: https://reddit.com/r/homeassistant
[releases-shield]: https://img.shields.io/github/release/hassio-addons/addon-airsonos.svg
[releases]: https://github.com/hassio-addons/addon-airsonos/releases
[repository]: https://github.com/hassio-addons/repository
[semver]: http://semver.org/spec/v2.0.0.htm

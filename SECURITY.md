# Security

Please report a security problem privately, not in a public issue: use this repository's "Report a vulnerability"
button under the Security tab, or email hello@chaosmos.studio.
Say what you found, where, and how to reproduce it. You will hear back within a week.

What matters most here:

- anything that would let someone publish a build, change the website at chaosmos.studio or reach the release
  workflow's secrets;
- anything in the Android app that sends data the privacy policy at https://chaosmos.studio/stitchfall/privacy/
  does not describe;
- a way for the browser version to load code from anywhere other than chaosmos.studio.

The Firebase configuration in `google-services.json` and the AdMob ids in `scripts/monetize.gd` ship inside every
copy of the Android app, so they are not secrets. The Firebase key only works from the studio's own signed apps.

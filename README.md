FasterBuild
===========

XCode5 plugin to toggle speed up build time via a bunch of compile/debug options, inspired by a [blog post at Spotify](http://labs.spotify.com/2013/11/04/shaving-off-time-from-the-ios-edit-build-test-cycle/) and our efforts at Twitter to speed up our build times.

### Settings that are toggled

The plugin calls a perl one liner to find and replace individual options:

* Debug Information Format - Dwarf vs Dwarf with dsym

### Authors

* Nicolas Flacco (@nflacco)
* Jordan Zucker
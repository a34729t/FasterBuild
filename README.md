FasterBuild
===========

XCode5 plugin to toggle speed up build time via a bunch of compile/debug options, inspired by a [blog post at Spotify](http://labs.spotify.com/2013/11/04/shaving-off-time-from-the-ios-edit-build-test-cycle/).

![Screenshot](https://raw.githubusercontent.com/a34729t/FasterBuild/master/screenshot.png)

### Instructions

Clone the project, build it in Xcode 5 and restart Xcode. To get a newer version, you'll need to delete the plugin directory:

    rm -rf /Users/$USER/Library/Application Support/Developer/Shared/Xcode/Plug-ins/FasterBuild.xcplugin

PS: Once we have this in Alcatraz, you can just use that...


### Settings that are toggled

The plugin calls a perl one liner to find and replace individual options:

    DEBUG_INFORMATION_FORMAT - Dwarf vs Dwarf with dsym

### TODO

Make the rest of these work:
    
    RUN_CLANG_STATIC_ANALYZER
    CLANG_ANALYZER_DEADCODE_DEADSTORES
    CLANG_ANALYZER_GCD
    CLANG_ANALYZER_MEMORY_MANAGEMENT
    CLANG_ANALYZER_OBJC_ATSYNC
    CLANG_ANALYZER_OBJC_COLLECTIONS
    CLANG_ANALYZER_OBJC_INCOMP_METHOD_TYPES
    CLANG_ANALYZER_OBJC_NSCFERROR
    CLANG_ANALYZER_OBJC_RETAIN_COUNT
    CLANG_ANALYZER_OBJC_SELF_INIT
    CLANG_ANALYZER_OBJC_UNUSED_IVARS
    CLANG_ANALYZER_SECURITY_INSECUREAPI_GETPW_GETS
    CLANG_ANALYZER_SECURITY_INSECUREAPI_MKSTEMP
    CLANG_ANALYZER_SECURITY_INSECUREAPI_UNCHECKEDRETURN
    CLANG_ANALYZER_SECURITY_INSECUREAPI_VFORK
    CLANG_ANALYZER_SECURITY_KEYCHAIN_API

### Authors

* Nicolas Flacco (@nflacco)
* Jordan Zucker

### TODO

* Recursive project file finding works
* Need: Use xcodeproject parsing library to check if a line exists
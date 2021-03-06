//
//  FasterBuild.m
//  FasterBuild
//
//  Created by Nicolas Flacco on 7/14/14.
//    Copyright (c) 2014 Nicolas Flacco. All rights reserved.
//

#import "FasterBuild.h"

#define FasterBuildKey @"FasterBuild"

static FasterBuild *sharedPlugin;

@interface FasterBuild()

@property (nonatomic, strong) NSMenuItem *actionMenuItem;
@property (nonatomic, strong) NSBundle *bundle;

@end

@implementation FasterBuild

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[self alloc] initWithBundle:plugin];
        });
    }
}

- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init]) {
        // reference to plugin's bundle, for resource acccess
        self.bundle = plugin;
        
        // Create menu items, initialize UI, etc.

        // Property for fast build menu item
        self.actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"untitled" action:@selector(toggleFasterBuild) keyEquivalent:@""];
        [self.actionMenuItem setTarget:self];
        
        // Add a separator at bottom of menu
        NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Product"];
        if (menuItem) {
            [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
            [[menuItem submenu] addItem:self.actionMenuItem];
        }
        
        // Init menu
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:FasterBuildKey];
        self.actionMenuItem.title = @"Enable Fast Build";
    }
    return self;
}

#define FB_DWARF            @"\"dwarf\""
#define FB_DWARF_DYSM       @"\"dwarf-with-dsym\""
#define FB_SHALLOW          @"shallow"
#define FB_DEEP             @"deep"
#define FB_YES              @"YES"
#define FB_NO               @"NO"

- (BOOL)checkIfExplicit:(NSString *)projectOption path:(NSString *)path
{
    NSString *command = [NSString stringWithFormat:@"grep -n '%@' %@", projectOption, path];
    NSString *output = [self runCommand:command];
    if (output.length > 0) {
        return YES;
    } else {
        return NO;
    }
}

- (void)toggleFasterBuild
{
    // Get list of project files
    NSString *path = [self currentProjectPath];
    NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    NSArray *pbxprojFiles = [dirFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.pbxproj'"]];
    NSString *joinedString = [pbxprojFiles componentsJoinedByString:@"/"];

    NSAlert *alert = [NSAlert alertWithMessageText:joinedString defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
    [alert runModal];


    NSArray *filePaths = [self recursivePathsForResourcesOfType:@"pbxproj" inDirectory:[self currentProjectPath]];
    for (NSString *pbxprojFilePath in filePaths) {
        if ([self checkIfExplicit:@"CLANG_STATIC_ANALYZER_MODE_ON_ANALYZE_ACTION" path:pbxprojFilePath]) {
            NSString *str = [NSString stringWithFormat:@"Inside --> CLANG_STATIC_ANALYZER_MODE_ON_ANALYZE_ACTION in %@", pbxprojFilePath];
            NSAlert *alert = [NSAlert alertWithMessageText:str defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
            [alert runModal];
        }
    }

    /*
    // Handle switching state
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL on = [userDefaults boolForKey:FasterBuildKey];
    
    if (on) { // Turn off
        [userDefaults setBool:NO forKey:FasterBuildKey];
        self.actionMenuItem.title = @"Enable Fast Build";
    } else { // Starting state, turn on
        [userDefaults setBool:YES forKey:FasterBuildKey];
        self.actionMenuItem.title = @"Disable Fast Build";
    }
    [[NSUserDefaults standardUserDefaults] synchronize];

    // Now we've changed state, toggle options
    on = !on;

    // Non-Booleans
    if (on) {
        [self toggleItem:@"DEBUG_INFORMATION_FORMAT" valueNew:FB_DWARF valueOld:FB_DWARF_DYSM];
        [self toggleInsertItem:@"CLANG_STATIC_ANALYZER_MODE_ON_ANALYZE_ACTION" valueNew:FB_SHALLOW valueOld:FB_DEEP];
    } else {
        [self toggleItem:@"DEBUG_INFORMATION_FORMAT" valueNew:FB_DWARF_DYSM valueOld:FB_DWARF];
        [self toggleInsertItem:@"CLANG_STATIC_ANALYZER_MODE_ON_ANALYZE_ACTION" valueNew:FB_DEEP valueOld:FB_SHALLOW];
    }
    */

    /*
    // Boolean Options
    NSString *old;
    NSString *new;
    if (on) {
        old = @"YES";
        new = @"NO";
    } else {
        old = @"NO";
        new = @"YES";
    }

    [self toggleItem:@"RUN_CLANG_STATIC_ANALYZER" valueNew:new valueOld:old];
    [self toggleItem:@"CLANG_ANALYZER_DEADCODE_DEADSTORES" valueNew:new valueOld:old];
    [self toggleItem:@"CLANG_ANALYZER_GCD" valueNew:new valueOld:old];
    [self toggleItem:@"CLANG_ANALYZER_MEMORY_MANAGEMENT" valueNew:new valueOld:old];
    [self toggleItem:@"CLANG_ANALYZER_OBJC_ATSYNC" valueNew:new valueOld:old];
    [self toggleItem:@"CLANG_ANALYZER_OBJC_COLLECTIONS" valueNew:new valueOld:old];
    [self toggleItem:@"CLANG_ANALYZER_OBJC_INCOMP_METHOD_TYPES" valueNew:new valueOld:old];
    [self toggleItem:@"CLANG_ANALYZER_OBJC_NSCFERROR" valueNew:new valueOld:old];
    [self toggleItem:@"CLANG_ANALYZER_OBJC_RETAIN_COUNT" valueNew:new valueOld:old];
    [self toggleItem:@"CLANG_ANALYZER_OBJC_SELF_INIT" valueNew:new valueOld:old];
    [self toggleItem:@"CLANG_ANALYZER_OBJC_UNUSED_IVARS" valueNew:new valueOld:old];
    [self toggleItem:@"CLANG_ANALYZER_SECURITY_INSECUREAPI_GETPW_GETS" valueNew:new valueOld:old];
    [self toggleItem:@"CLANG_ANALYZER_SECURITY_INSECUREAPI_MKSTEMP" valueNew:new valueOld:old];
    [self toggleItem:@"CLANG_ANALYZER_SECURITY_INSECUREAPI_UNCHECKEDRETURN" valueNew:new valueOld:old];
    [self toggleItem:@"CLANG_ANALYZER_SECURITY_INSECUREAPI_VFORK" valueNew:new valueOld:old];
    [self toggleItem:@"CLANG_ANALYZER_SECURITY_KEYCHAIN_API" valueNew:new valueOld:old];
     */
}

- (void)toggleInsertItem:(NSString *)item valueNew:(NSString *)valueNew valueOld:(NSString *)valueOld
{
    // This handles the specific case where stuff can be a default option in the
    // project file, so there is no line for it. To turn on the feature, we must
    // insert it. To turn off, we must delete.
    NSString *workspacePath = [self currentProjectPath];
    NSString *old = [NSString stringWithFormat:@"%@ = %@;", item, valueOld];
    NSString *new = [NSString stringWithFormat:@"%@ = %@;", item, valueNew];

    // Loop over project files
    // First, we need to make see if there are any matches:

    // For example: perl -p -i -e 's/[OLD]/[NEW]/g' `find . -name *.pbxproj`
    NSString *command = [NSString stringWithFormat:@"perl -p -i -e 's/%@/%@/g' `find %@ -name *.pbxproj`", old, new, workspacePath];
    [self runCommand:command];

}

- (void)toggleItem:(NSString *)item valueNew:(NSString *)valueNew valueOld:(NSString *)valueOld
{
    NSString *workspacePath = [self currentProjectPath];
    NSString *old = [NSString stringWithFormat:@"%@ = %@;", item, valueOld];
    NSString *new = [NSString stringWithFormat:@"%@ = %@;", item, valueNew];

    // For example: perl -p -i -e 's/[OLD]/[NEW]/g' `find . -name *.pbxproj`
    NSString *command = [NSString stringWithFormat:@"perl -p -i -e 's/%@/%@/g' `find %@ -name *.pbxproj`", old, new, workspacePath];
    [self runCommand:command];
}

- (NSString *)runCommand:(NSString *)commandToRun
{
    // From http://stackoverflow.com/a/12310154/581135
    // Other methods didn't seem to work in Xcode, but worked as a regular terminal app!
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/sh"];
    
    NSArray *arguments = [NSArray arrayWithObjects:
                          @"-c" ,
                          [NSString stringWithFormat:@"%@", commandToRun],
                          nil];
    NSLog(@"run command: %@",commandToRun);
    [task setArguments: arguments];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *data;
    data = [file readDataToEndOfFile];
    
    NSString *output;
    output = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    return output;
}

- (NSArray *)recursivePathsForResourcesOfType:(NSString *)type inDirectory:(NSString *)directoryPath{

    NSMutableArray *filePaths = [[NSMutableArray alloc] init];

    // Enumerators are recursive
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:directoryPath];

    NSString *filePath;
    while ((filePath = [enumerator nextObject]) != nil){

        // If we have the right type of file, add it to the list
        // Make sure to prepend the directory path
        if([[filePath pathExtension] isEqualToString:type]){
            [filePaths addObject:[directoryPath stringByAppendingPathComponent:filePath]];
        }
    }
    return filePaths;
}

- (NSString *)currentProjectPath
{
    // 1) Get project path
    // This gets you something like:
    //  /Users/nflacco/Projects/ios/alcatraz/FasterBuild/FasterBuild.xcodeproj
    // See http://stackoverflow.com/questions/21054699/get-the-path-of-current-project-opened-in-xcode-plugin

    NSArray *workspaceWindowControllers = [NSClassFromString(@"IDEWorkspaceWindowController") valueForKey:@"workspaceWindowControllers"];
    id workSpace;
    for (id controller in workspaceWindowControllers) {
        if ([[controller valueForKey:@"window"] isEqual:[NSApp keyWindow]]) {
            workSpace = [controller valueForKey:@"_workspace"];
        }
    }

    // 2) We want everything but the last element to get the root project folder
    NSString *pathWithProject = [[workSpace valueForKey:@"representingFilePath"] valueForKey:@"_pathString"];
    NSArray *splitPath = [pathWithProject componentsSeparatedByString:@"/"];
    NSString *joinedString = [[splitPath subarrayWithRange:NSMakeRange(0, splitPath.count-2)] componentsJoinedByString:@"/"];
    // NOTE: For our monster project, we have to do -2, because of our directory structure

    return joinedString;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

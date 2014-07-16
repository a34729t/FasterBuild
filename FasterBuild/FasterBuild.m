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

@property (nonatomic, strong) NSBundle *bundle;
@property (nonatomic, strong) NSMenuItem *actionMenuItem;

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
        [self toggleMenu:NO]; // default is Off
    }
    return self;
}

- (void)toggleMenu:(BOOL)on
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (on) {
        [userDefaults setBool:YES forKey:FasterBuildKey];
        self.actionMenuItem.title = @"Disable Fast Build";
    } else {
        [userDefaults setBool:NO forKey:FasterBuildKey];
        self.actionMenuItem.title = @"Enable Fast Build";
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)toggleFasterBuild
{
    BOOL on = [[NSUserDefaults standardUserDefaults] boolForKey:FasterBuildKey];
    [self toggleMenu:!on];
    NSString *workspacePath = [self currentProjectPath];

    
    // TODO: Run an NSTask to modify project on a line-item basis
    // 1. Print out the path of the current project's project files
    
    
    
    // 2. Do line item changes
    if (on) {
        [self lineItemReplace:@"DEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\";" with:@"DEBUG_INFORMATION_FORMAT = \"dwarf\";" path:workspacePath];
    } else {
        [self lineItemReplace:@"DEBUG_INFORMATION_FORMAT = \"dwarf\";" with:@"DEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\";" path:workspacePath];
    }
    
//    NSString *msg;
//    if (on) {
//        msg = @"On!";
//    } else {
//        msg = @"Off!";
//    }
//    NSAlert *alert = [NSAlert alertWithMessageText:msg defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
//    [alert runModal];
    
}

- (void)lineItemReplace:(NSString *)old with:(NSString *)new path:(NSString *)workspacePath
{
    // In theory, trying to do this
    // http://stackoverflow.com/questions/24774122/nstask-calling-perl-and-piping-in-find-not-working
    
    // But it doesn't work!
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/sh"];
    NSString *regex = [NSString stringWithFormat:@"'s/%@/%@/g'", old, new];
    NSString *pathArg = [NSString stringWithFormat:@"`find %@ -name *.pbxproj`", workspacePath];
    [task setArguments:@[ @"/usr/bin/perl", @"-p", @"-i", @"-e", regex, pathArg]];
    [task launch];
}

- (NSString *)currentProjectPath
{
    // See http://stackoverflow.com/questions/21054699/get-the-path-of-current-project-opened-in-xcode-plugin
    
    NSArray *workspaceWindowControllers = [NSClassFromString(@"IDEWorkspaceWindowController") valueForKey:@"workspaceWindowControllers"];
    
    id workSpace;
    for (id controller in workspaceWindowControllers) {
        if ([[controller valueForKey:@"window"] isEqual:[NSApp keyWindow]]) {
            workSpace = [controller valueForKey:@"_workspace"];
        }
    }
    
    NSString *workspacePath = [[workSpace valueForKey:@"representingFilePath"] valueForKey:@"_pathString"];
    
    // This gets you something like:
    //  /Users/nflacco/Projects/ios/alcatraz/FasterBuild/FasterBuild.xcodeproj
    
    return workspacePath;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

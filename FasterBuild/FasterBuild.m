//
//  FasterBuild.m
//  FasterBuild
//
//  Created by Nicolas Flacco on 7/14/14.
//    Copyright (c) 2014 Nicolas Flacco. All rights reserved.
//

#import "FasterBuild.h"

#define FasterBuildKey @"FasterBuild"


#define DEBUG_INFO_OFF              @"DEBUG_INFORMATION_FORMAT = \"dwarf\";"
#define DEBUG_INFO_ON               @"DEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\";"

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
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:FasterBuildKey];
        [self toggleFasterBuild];
    }
    return self;
}

- (void)toggleFasterBuild
{
    NSString *workspacePath = [self currentProjectPath];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL on = [userDefaults boolForKey:FasterBuildKey];
    
    if (!on) { // Starting state, turn on
        [userDefaults setBool:YES forKey:FasterBuildKey];
        self.actionMenuItem.title = @"Enable Fast Build";
        [self lineItemReplace:DEBUG_INFO_OFF with:DEBUG_INFO_ON path:workspacePath];
    } else {
        [userDefaults setBool:NO forKey:FasterBuildKey];
        self.actionMenuItem.title = @"Disable Fast Build";
        [self lineItemReplace:DEBUG_INFO_ON with:DEBUG_INFO_OFF path:workspacePath];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)currentProjectPath
{
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

    return [[workSpace valueForKey:@"representingFilePath"] valueForKey:@"_pathString"];
}


- (void)lineItemReplace:(NSString *)old with:(NSString *)new path:(NSString *)workspacePath
{
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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

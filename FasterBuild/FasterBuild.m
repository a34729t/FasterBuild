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
    
    NSString *msg;
    if (on) {
        msg = @"On!";
    } else {
        msg = @"Off!";
    }
    NSAlert *alert = [NSAlert alertWithMessageText:msg defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
    [alert runModal];
    
    // TODO: Run an NSTask to modify project on a line-item basis
    
    
    
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

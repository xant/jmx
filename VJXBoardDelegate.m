//
//  VJXBoardDelegate.m
//  VeeJay
//
//  Created by Igor Sutton on 8/27/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXBoardDelegate.h"
#import "VJXBoardEntity.h"
#import "VJXQtVideoLayer.h"
#import "VJXOpenGLScreen.h"
#import "VJXImageLayer.h"
#import "VJXMixer.h"

@implementation VJXBoardDelegate

@synthesize board;

static id sharedBoard = nil;

+ (void)setSharedBoard:(id)aBoard
{
    sharedBoard = aBoard;
}

+ (id)sharedBoard
{
    return sharedBoard;
}

- (void)awakeFromNib
{
    [VJXBoardDelegate setSharedBoard:board];
}

- (void)openFilePanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
    VJXEntity *entity = (VJXEntity *)contextInfo;
    
    if(returnCode == NSOKButton){
        NSLog(@"openFilePanel: OK\n");    
    } else if(returnCode == NSCancelButton) {
        NSLog(@"openFilePanel: Cancel\n");
        return;
    } else {
        NSLog(@"openFilePanel: Error %3d\n",returnCode);
        return;
    } // end if     
    NSString * directory = [panel directory];
    NSLog(@"openFile directory = %@\n",directory);
    
    NSString * fileName = [panel filename];
    NSLog(@"openFile filename = %@\n",fileName);
    
    if (fileName) {
        if ([entity respondsToSelector:@selector(open:)]) {
            [entity performSelector:@selector(open:) withObject:fileName];
        } else {
            NSLog(@"Entity %@ doesn't respond to 'open:'\n");
            return;
        }
        VJXBoardEntity *entityView = [[VJXBoardEntity alloc] initWithEntity:entity];
        [board addSubview:entityView];
        if ([entity respondsToSelector:@selector(start)])
            [entity performSelector:@selector(start)];
        else
             NSLog(@"Entity %@ doesn't respond to 'start'. Not a VJXThreadedEntity ?\n");
    }
}

- (void)openFile:(NSArray *)types forEntity:(VJXEntity *)entity
{    
    NSOpenPanel *fileSelectionPanel    = [NSOpenPanel openPanel];
    
    
    [fileSelectionPanel 
     beginSheetForDirectory:nil 
     file:nil
     types:types 
     modalForWindow:[board window]
     modalDelegate:self 
     didEndSelector:@selector(openFilePanelDidEnd: returnCode: contextInfo:) 
     contextInfo:entity];    
    [fileSelectionPanel setCanChooseFiles:YES];
} // end openFile

- (IBAction)addEntity:(id)sender
{
    NSRect frame = NSMakeRect(10.0, 10.0, 200.0, 100.0);
    VJXBoardEntity *entity = [[VJXBoardEntity alloc] initWithFrame:frame];
    [board addSubview:entity];
    [board setNeedsDisplay:YES];
}

- (IBAction)addMovieLayer:(id)sender
{
    
    NSArray *types = [NSArray arrayWithObjects:
                      @"avi", @"mov", @"mpg", @"asf", nil];
    
    VJXQtVideoLayer *movieLayer = [[VJXQtVideoLayer alloc] init];
    [self openFile:types forEntity:movieLayer];
}


- (IBAction)addImageLayer:(id)sender
{
    NSArray *types = [NSArray arrayWithObjects:
                      @"jpg", @"png", @"tif", @"bmp", 
                      @"gif", @"pdf", nil];

    VJXImageLayer *imageLayer = [[VJXImageLayer alloc] init];
    [self openFile:types forEntity:imageLayer];
}

- (IBAction)addMixerLayer:(id)sender
{
    VJXMixer *mixer = [[VJXMixer alloc] init];
    VJXBoardEntity *entity = [[VJXBoardEntity alloc] initWithEntity:mixer];
    [board addSubview:entity];
    [mixer start];
}

- (IBAction)addOutputScreen:(id)sender
{
    VJXOpenGLScreen *screen = [[VJXOpenGLScreen alloc] init];
    VJXBoardEntity *entity = [[VJXBoardEntity alloc] initWithEntity:screen];
    [board addSubview:entity];
    NSLog(@"%s", _cmd);
}

@end

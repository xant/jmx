//
//  JMXBoardView.m
//  JMX
//
//  Created by Igor Sutton on 8/26/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
//
//  This file is part of JMX
//
//  JMX is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Foobar is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with JMX.  If not, see <http://www.gnu.org/licenses/>.
//

#import "JMXBoardView.h"
#import "JMXQtMovieEntity.h"
#import "JMXAudioFileEntity.h"
#import "JMXScriptFile.h"
#import "JMXFileRead.h"
#import "JMXRunLoop.h"

@implementation JMXBoardView

@synthesize boardViewController;

#pragma mark -
#pragma mark Initialization

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self registerForDraggedTypes:[NSArray arrayWithObjects:NSURLPboardType,NSFilenamesPboardType,@"JMXLibraryTableViewDataType",nil]];
    }
    return self;
}

- (void)awakeFromNib
{
    //JMXBoardLayer *boardLayer = [[[JMXBoardLayer alloc] init] autorelease];
    //self.layer = boardLayer;
    [self setWantsLayer:YES];
    CGColorRef backgroundColor = CGColorCreateGenericRGB(1.0f, 1.0f, 1.0f, 1.0f);
    self.layer.backgroundColor = backgroundColor;
    CFRelease(backgroundColor);
    self.layer.geometryFlipped = NO;
}

#pragma mark -
#pragma mark Open file

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode userInfo:(NSDictionary *)userInfo
{
    if (returnCode == NSCancelButton)
        return;
    
    NSString *filename = [[panel URL] path];
    
    if (filename) {
        JMXEntity *anEntity = [[[userInfo objectForKey:@"class"] alloc] init];
        [(id<JMXFileRead>)anEntity open:filename];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXBoardEntityWasCreated"
                                                            object:anEntity
                                                          userInfo:userInfo];
        [anEntity release];
    }
}

#pragma mark -
#pragma mark Dragging operations

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    return NSDragOperationCopy;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return YES; //[NSURL URLFromPasteboard: [sender draggingPasteboard]];
}

- (void)createEntityWithClass:(Class)aClass atPoint:(NSPoint)aPoint
{
    NSMutableDictionary *userInfo = [[[NSMutableDictionary alloc] init] autorelease];
    [userInfo setObject:[NSValue valueWithPoint:aPoint] forKey:@"origin"];
    
    if ([aClass conformsToProtocol:@protocol(JMXFileRead)]) {
        [userInfo setObject:aClass forKey:@"class"];
        
        NSOpenPanel *panel = [NSOpenPanel openPanel];
        panel.allowedFileTypes = [aClass performSelector:@selector(supportedFileTypes)];
        [panel beginSheetModalForWindow:[self window]
                      completionHandler:^(NSInteger returnCode) {
                          if (returnCode == NSFileHandlingPanelOKButton) 
                              [self openPanelDidEnd:panel returnCode:returnCode userInfo:userInfo];
                      }];
    }
    else {
        JMXEntity *anEntity = [[[aClass alloc] init] autorelease];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXBoardEntityWasCreated"
                                                            object:anEntity
                                                          userInfo:userInfo];
    }
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	/*------------------------------------------------------
     method that should handle the drop data
     --------------------------------------------------------*/

	// draggingSource returns nil if another application started the drag
	// operation. We'll assume all drags will either start from Finder or from
	// our library window.
    if ([sender draggingSource] == nil) {
        NSURL* fileURL;

        //if the drag comes from a file, set the window title to the filename
        fileURL=[NSURL URLFromPasteboard: [sender draggingPasteboard]];
        NSString *fileName = [fileURL lastPathComponent];
        NSArray *components = [fileName componentsSeparatedByString:@"."];
        // TODO - GENERALIZE
        if ([[JMXQtMovieEntity supportedFileTypes] containsObject:[components lastObject]]) {
            JMXQtMovieEntity *entity = [[JMXQtMovieEntity alloc] init];
            if (fileName && [entity conformsToProtocol:@protocol(JMXFileRead)]) {
                [entity performSelector:@selector(open:) withObject:[fileURL path]];
            }
            /*if ([entity conformsToProtocol:@protocol(JMXRunLoop)])
                [entity performSelector:@selector(start)];*/
            [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXBoardEntityWasCreated" object:entity];

            [entity release];
        } else if ([[JMXAudioFileEntity supportedFileTypes] containsObject:[components lastObject]]) {
            JMXAudioFileEntity *entity = [[JMXAudioFileEntity alloc] init];
            if (fileName && [entity conformsToProtocol:@protocol(JMXFileRead)]) {
                [entity performSelector:@selector(open:) withObject:[fileURL path]];
            }
            /*if ([entity conformsToProtocol:@protocol(JMXRunLoop)])
                [entity performSelector:@selector(start)];*/
            [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXBoardEntityWasCreated" object:entity];
            [entity release];
        } else if ([[components lastObject] isEqualToString:@"js"]) {
            JMXScriptFile *entity = [[JMXScriptFile alloc] init];
            if (fileName && [entity conformsToProtocol:@protocol(JMXFileRead)]) {
                [entity performSelector:@selector(open:) withObject:[fileURL path]];
            }
            /*if ([entity conformsToProtocol:@protocol(JMXRunLoop)])
             [entity performSelector:@selector(start)];*/
            [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXBoardEntityWasCreated" object:entity];
            [entity release];
        } // TODO - generalize
    }
	else {
		NSPasteboard *pboard = [sender draggingPasteboard];
		NSData *data = [pboard dataForType:@"JMXLibraryTableViewDataType"];
		NSString *className = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        [self createEntityWithClass:NSClassFromString(className) atPoint:[sender draggingLocation]];
	}

    return YES;
}

#pragma mark -
#pragma mark Helpers

- (CGPoint)translatePointToBoardLayer:(NSPoint)aPoint
{
    NSPoint localPoint = [self convertPoint:aPoint fromView:nil];
    NSPoint rootPoint = [self convertPointToBase:localPoint];
    CGPoint translatedPoint = NSPointToCGPoint(rootPoint);
    return translatedPoint;
}

- (JMXPinLayer *)pinLayerAtPoint:(NSPoint)aPoint
{
    CALayer *aLayer = [self.layer hitTest:[self translatePointToBoardLayer:aPoint]];

    if ([aLayer isKindOfClass:[JMXPinLayer class]])
        return (JMXPinLayer *)aLayer;

    return nil;
}

- (JMXEntityLayer *)entityLayerAtPoint:(NSPoint)aPoint
{
    CALayer *aLayer = [self.layer hitTest:[self translatePointToBoardLayer:aPoint]];

    if ([aLayer isKindOfClass:[JMXEntityLayer class]])
        return (JMXEntityLayer *)aLayer;

    return nil;
}

- (JMXConnectorLayer *)connectorLayerAtPoint:(NSPoint)aPoint
{
    CALayer *aLayer = [self.layer hitTest:[self translatePointToBoardLayer:aPoint]];

    if ([aLayer isKindOfClass:[JMXConnectorLayer class]])
        return (JMXConnectorLayer *)aLayer;

    return nil;
}

- (CGFloat)maxZPosition
{
    CGFloat zPosition = ((CALayer *)[[self.layer sublayers] objectAtIndex:0]).zPosition;

    for (CALayer *l in [self.layer sublayers]) {
        if (l.zPosition >= zPosition)
            zPosition = l.zPosition + 0.1f;
    }

    return zPosition;
}

@end

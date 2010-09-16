//
//
//  This file is part of VeeJay
//
//  VeeJay is free software: you can redistribute it and/or modify
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
//  along with VeeJay.  If not, see <http://www.gnu.org/licenses/>.
//
//  VJXDocument.m by Igor Sutton on 9/15/10.
//

#import "VJXDocument.h"
#import "VJXQtVideoLayer.h"
#import "VJXQtCaptureLayer.h"
#import "VJXVideoMixer.h"
#import "VJXImageLayer.h"
#import "VJXOpenGLScreen.h"
#import "VJXBoard.h"
#import <QTKit/QTMovie.h>


@implementation VJXDocument

@synthesize entities;
@synthesize board;

- (id)init
{
    if ((self = [super init]) != nil) {
        entities = [[NSMutableArray alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(anEntityWasRemoved:) name:@"VJXEntityWasRemoved" object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [board release];
    [entities release];
    [super dealloc];
}

#pragma mark -
#pragma mark NSDocument

- (NSString *)windowNibName
{
    return @"VJXDocument";
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    NSMutableData *data;
    NSKeyedArchiver *archiver;
    
    data = [NSMutableData data];
    archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    
    [archiver encodeObject:entities forKey:@"Entities"];
    [archiver finishEncoding];
    [archiver release];
    
    return data;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    NSKeyedUnarchiver *unarchiver;
    
    unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    entities = [[unarchiver decodeObjectForKey:@"Entities"] retain];
    [unarchiver finishDecoding];
    [unarchiver release];
    return YES;
}

#pragma mark -
#pragma mark Interface Builder actions

- (IBAction)addQTVideoLayer:(id)sender
{
    NSArray *types = [QTMovie movieTypesWithOptions:QTIncludeCommonTypes];
    VJXQtVideoLayer *entity = [[VJXQtVideoLayer alloc] init];
    [self openFileWithTypes:types forEntity:entity];
}

- (IBAction)addVideoMixer:(id)sender
{
    VJXVideoMixer *entity = [[VJXVideoMixer alloc] init];
    [entities addObject:entity];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"VJXEntityWasCreated" object:entity];
    [entity release];
}

- (IBAction)addImageLayer:(id)sender
{
    NSArray *types = [NSImage imageTypes];
    VJXImageLayer *entity = [[VJXImageLayer alloc] init];
    [entities addObject:entity];
    [self openFileWithTypes:types forEntity:entity];
}

- (IBAction)addOpenGLScreen:(id)sender
{
    VJXOpenGLScreen *entity = [[VJXOpenGLScreen alloc] init];
    [entities addObject:entity];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"VJXEntityWasCreated" object:entity];
    [entity release];
}

- (IBAction)addQtCaptureLayer:(id)sender
{
    VJXQtCaptureLayer *entity = [[VJXQtCaptureLayer alloc] init];
    [entities addObject:entity];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"VJXEntityWasCreated" object:entity];
    [entity release];
}

- (IBAction)removeSelected:(id)sender
{
    [board removeSelected:sender];
}

#pragma mark -
#pragma mark Open file

- (void)openFileWithTypes:(NSArray *)types forEntity:(VJXEntity *)entity
{
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel beginSheetForDirectory:nil
                             file:nil
                            types:types
                   modalForWindow:[self windowForSheet]
                    modalDelegate:self
                   didEndSelector:@selector(openPanelDidEnd:returnCode:entity:)
                      contextInfo:entity];
    [panel setCanChooseFiles:YES];
}

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode entity:(VJXEntity *)entity
{
    if (returnCode == NSCancelButton) {
        [entity release];
        return;
    }
    
    NSString *filename = [panel filename];
    
    if (filename && [entity respondsToSelector:@selector(open:)]) {
        [entity performSelector:@selector(open:) withObject:filename];
    }
    
    [entities addObject:entity];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"VJXEntityWasCreated" object:entity];
    
    [entity release];
}

#pragma mark -
#pragma mark Notifications

- (void)anEntityWasRemoved:(NSNotification *)aNotification
{
    VJXEntity *entity = [aNotification object];
    [entities removeObject:entity];
}

@end

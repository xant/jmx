//
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
//  JMXDocument.m by Igor Sutton on 9/15/10.
//

#import "JMXDocument.h"
#import "JMXBoardView.h"
#import "JMXFileRead.h"
#import <QTKit/QTMovie.h>


@implementation JMXDocument

@synthesize boardView;
@synthesize entities;
@synthesize entitiesFromFile;
@synthesize entitiesPosition;
@synthesize boardViewController;
@synthesize boardScrollView;

- (id)init
{
    if ((self = [super init]) != nil) {
        entities = [[NSMutableArray alloc] init];
        entitiesFromFile = [[NSMutableArray alloc] init];
        entitiesPosition = [[NSMutableDictionary alloc] init];
		
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(anEntityWasRemoved:) name:@"JMXBoardEntityWasRemoved" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(anEntityWasMoved:) name:@"JMXBoardEntityWasMoved" object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [boardView release];
    [entities release];
    [entitiesPosition release];
    [super dealloc];
}

#pragma mark -
#pragma mark NSDocument

- (void)makeWindowControllers
{
	JMXWindowController *windowController = [[JMXWindowController alloc] initWithWindowNibName:@"JMXWindow"];
	[self addWindowController:windowController];
}

#pragma mark -
#pragma mark Open file

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode userInfo:(NSDictionary *)userInfo
{
    if (returnCode == NSCancelButton)
        return;

    NSString *filename = [panel filename];

    if (filename) {
        JMXEntity *anEntity = [[[userInfo objectForKey:@"class"] alloc] init];
        [(id<JMXFileRead>)anEntity open:filename];
        [entities addObject:anEntity];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXBoardEntityWasCreated" object:anEntity userInfo:userInfo];
        [anEntity release];
    }

    [userInfo release];
}

- (void)createEntityWithClass:(Class)aClass atPoint:(NSPoint)aPoint
{
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setObject:[NSValue valueWithPoint:aPoint] forKey:@"origin"];

    if ([aClass conformsToProtocol:@protocol(JMXFileRead)]) {
        [userInfo setObject:aClass forKey:@"class"];

        NSOpenPanel *panel = [NSOpenPanel openPanel];
        [panel beginSheetForDirectory:nil
                                 file:nil
                                types:[aClass performSelector:@selector(supportedFileTypes)]
                       modalForWindow:[self windowForSheet]
                        modalDelegate:self
                       didEndSelector:@selector(openPanelDidEnd:returnCode:userInfo:)
                          contextInfo:[userInfo retain]];
    }
    else {
        JMXEntity *anEntity = [[aClass alloc] init];
        [entities addObject:anEntity];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXBoardEntityWasCreated" object:anEntity userInfo:userInfo];
        [anEntity release];
    }
    [userInfo release];
}

#pragma mark -
#pragma mark Notifications

- (void)anEntityWasRemoved:(NSNotification *)aNotification
{
    NSLog(@"%s", _cmd);
    JMXEntity *entity = [aNotification object];
    [entitiesPosition removeObjectForKey:entity];
    [entities removeObject:entity];
}

- (void)anEntityWasMoved:(NSNotification *)aNotification
{
    JMXEntityLayer *entity = [aNotification object];
    NSString *origin = [[aNotification userInfo] objectForKey:@"origin"];
    [entitiesPosition setObject:origin forKey:entity.entity];
}

@end

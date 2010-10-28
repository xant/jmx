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
#import "VJXBoardView.h"
#import "VJXFileRead.h"
#import <QTKit/QTMovie.h>


@implementation VJXDocument

@synthesize board;
@synthesize entities;
@synthesize entitiesFromFile;
@synthesize entitiesPosition;

- (id)init
{
    if ((self = [super init]) != nil) {
        entities = [[NSMutableArray alloc] init];
        entitiesFromFile = [[NSMutableArray alloc] init];
        entitiesPosition = [[NSMutableDictionary alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(anEntityWasRemoved:) name:@"VJXBoardEntityWasRemoved" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(anEntityWasMoved:) name:@"VJXBoardEntityWasMoved" object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [board release];
    [entities release];
    [entitiesPosition release];
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
    NSXMLElement *root = (NSXMLElement *)[NSXMLNode elementWithName:@"entities"];

    for (VJXEntity *entity in entities) {
        NSXMLElement *e = [NSXMLElement elementWithName:[entity className]];
        NSString *originString = [entitiesPosition objectForKey:entity];
        NSXMLElement *origin = [NSXMLElement elementWithName:@"origin"];
        [origin setStringValue:originString];
        [e addChild:origin];
        [root addChild:e];
    }

    NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithRootElement:root];
    [xmlDoc setVersion:@"1.0"];
    [xmlDoc setCharacterEncoding:@"UTF-8"];

    NSData *data = [xmlDoc XMLDataWithOptions:NSXMLDocumentXMLKind];

    [xmlDoc release];

    return data;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    NSError *error = nil;
    NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithData:data options:NSXMLDocumentTidyXML error:&error];

    NSXMLNode *aNode = [[xmlDoc rootElement] nextNode];

    if (aNode) {
        while (1) {
            NSString *className = [aNode name];
            Class aClass = NSClassFromString(className);
            VJXEntity *entity = [[aClass alloc] init];
            NSXMLNode *origin = [aNode childAtIndex:0];
            [entitiesPosition setObject:[origin stringValue] forKey:entity];
            [entities addObject:entity];
            [entity release];
            if ((aNode = [aNode nextSibling]) == nil)
                break;
        }
    }

    [xmlDoc release];

    return YES;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController
{
    NSMutableDictionary *userInfo = nil;
    for (id e in entities) {
        userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:[entitiesPosition objectForKey:e] forKey:@"origin"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"VJXBoardEntityWasCreated" object:e userInfo:userInfo];
    }
}

#pragma mark -
#pragma mark Interface Builder actions

#pragma mark -
#pragma mark Open file

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode userInfo:(NSDictionary *)userInfo
{
    if (returnCode == NSCancelButton)
        return;

    NSString *filename = [panel filename];

    if (filename) {
        VJXEntity *anEntity = [[[userInfo objectForKey:@"class"] alloc] init];
        [(id<VJXFileRead>)anEntity open:filename];
        [entities addObject:anEntity];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"VJXBoardEntityWasCreated" object:anEntity userInfo:userInfo];
        [anEntity release];
    }

    [userInfo release];
}

- (void)createEntityWithClass:(Class)aClass atPoint:(NSPoint)aPoint
{
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setObject:[NSValue valueWithPoint:aPoint] forKey:@"origin"];

    if ([aClass conformsToProtocol:@protocol(VJXFileRead)]) {
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
        VJXEntity *anEntity = [[aClass alloc] init];
        [entities addObject:anEntity];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"VJXBoardEntityWasCreated" object:anEntity userInfo:userInfo];
        [anEntity release];
    }
    [userInfo release];
}

#pragma mark -
#pragma mark Notifications

- (void)anEntityWasRemoved:(NSNotification *)aNotification
{
    VJXEntity *entity = [aNotification object];
    [entitiesPosition removeObjectForKey:entity];
    [entities removeObject:entity];
}

- (void)anEntityWasMoved:(NSNotification *)aNotification
{
    VJXEntityLayer *entity = [aNotification object];
    NSString *origin = [[aNotification userInfo] objectForKey:@"origin"];
    [entitiesPosition setObject:origin forKey:entity.entity];
}

@end

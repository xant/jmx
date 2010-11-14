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

@synthesize board;
@synthesize entities;
@synthesize entitiesFromFile;
@synthesize entitiesPosition;
@synthesize documentSplitView;
@synthesize inspectorPanel;

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
    [board release];
    [entities release];
    [entitiesPosition release];
    [super dealloc];
}

#pragma mark -
#pragma mark NSDocument

- (NSString *)windowNibName
{
    return @"JMXDocument";
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    NSXMLElement *root = (NSXMLElement *)[NSXMLNode elementWithName:@"entities"];

    for (JMXEntity *entity in entities) {
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
            JMXEntity *entity = [[aClass alloc] init];
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
        [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXBoardEntityWasCreated" object:e userInfo:userInfo];
    }

	[documentSplitView setPosition:200.0f ofDividerAtIndex:0];
	[documentSplitView setPosition:([documentSplitView bounds].size.width - 300.0f) ofDividerAtIndex:1];
	[documentSplitView adjustSubviews];
}

#pragma mark -
#pragma mark Interface Builder actions

- (IBAction)toggleInspector:(id)sender
{
	NSLog(@"sender: %@", sender);
	NSMenuItem *menuItem = (NSMenuItem *)sender;
	if ([documentSplitView isSubviewCollapsed:inspectorPanel]) {
		[inspectorPanel setHidden:NO];
		[documentSplitView setPosition:200.0f ofDividerAtIndex:0];
		[documentSplitView setPosition:([documentSplitView bounds].size.width - 200.0f) ofDividerAtIndex:1];
		[documentSplitView adjustSubviews];
		[menuItem setTitle:@"Hide Inspector"];
	}
	else {
		[inspectorPanel setHidden:YES];
		[documentSplitView adjustSubviews];
		[documentSplitView setPosition:200.0f ofDividerAtIndex:0];
		[menuItem setTitle:@"Show Inspector"];
	}

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

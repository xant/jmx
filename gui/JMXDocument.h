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
//  JMXDocument.h by Igor Sutton on 9/15/10.
//

#import <Cocoa/Cocoa.h>
#import "JMXEntity.h"
#import "JMXBoardView.h"
#import "JMXBoardViewController.h"
#import "JMXWindowController.h"
#import "JMXBoardViewController.h"


@class JMXBoardView;
@class JMXBoardViewController;
@class JMXEntityInspectorPanel;

@interface JMXDocument : NSDocument {
    JMXBoardView *boardView;
    NSMutableArray *entities;
    NSMutableArray *entitiesFromFile;
    NSMutableDictionary *entitiesPosition;
	JMXBoardViewController *boardViewController;
	NSScrollView *boardScrollView;
}

@property (nonatomic, retain) IBOutlet JMXBoardView *boardView;
@property (nonatomic, retain) NSMutableArray *entities;
@property (nonatomic, retain) NSMutableArray *entitiesFromFile;
@property (nonatomic, retain) NSMutableDictionary *entitiesPosition;
@property (nonatomic, retain) IBOutlet JMXBoardViewController *boardViewController;
@property (nonatomic, assign) IBOutlet NSScrollView *boardScrollView;

#pragma mark -
#pragma mark Open file

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode userInfo:(NSDictionary *)userInfo;
- (void)createEntityWithClass:(Class)aClass atPoint:(NSPoint)aPoint;

#pragma mark -
#pragma mark Notifications

- (void)anEntityWasRemoved:(NSNotification *)aNotification;

@end

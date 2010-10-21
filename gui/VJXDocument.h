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
//  VJXDocument.h by Igor Sutton on 9/15/10.
//

#import <Cocoa/Cocoa.h>
#import "VJXEntity.h"
#import "VJXBoardView.h"

@class VJXBoardView;

@interface VJXDocument : NSDocument {
    VJXBoardView *board;
    NSMutableArray *entities;
    NSMutableArray *entitiesFromFile;
    NSMutableDictionary *entitiesPosition;
}

@property (nonatomic, retain) IBOutlet VJXBoardView *board;
@property (nonatomic, retain) NSMutableArray *entities;
@property (nonatomic, retain) NSMutableArray *entitiesFromFile;
@property (nonatomic, retain) NSMutableDictionary *entitiesPosition;

#pragma mark -
#pragma mark Interface Builder actions

- (IBAction)removeSelected:(id)sender;

#pragma mark -
#pragma mark Open file

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode userInfo:(NSDictionary *)userInfo;
- (void)createEntityWithClass:(Class)aClass atPoint:(NSPoint)aPoint;

#pragma mark -
#pragma mark Notifications

- (void)anEntityWasRemoved:(NSNotification *)aNotification;

@end

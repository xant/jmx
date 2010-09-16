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
//  VJXBoardEntityOutlet.m by Igor Sutton on 9/8/10.
//

#import "VJXBoardEntityOutlet.h"

@implementation VJXBoardEntityOutlet

@synthesize pin;
@synthesize pinName;
@synthesize output;
@synthesize entity;

- (id)initWithPin:(VJXPin *)thePin andPoint:(NSPoint)thePoint isOutput:(BOOL)isOutput entity:(VJXBoardEntity *)anEntity;
{
    NSRect frame;
    frame = NSMakeRect(thePoint.x, thePoint.y, ENTITY_OUTLET_WIDTH, ENTITY_OUTLET_HEIGHT);

    if ((self = [super initWithFrame:frame]) != nil) {
        NSPoint pinPoint;
        NSRect labelRect;

        if (isOutput) {
            pinPoint = NSMakePoint(frame.size.width - ENTITY_OUTLET_LABEL_PADDING_FOR_OUTPUT, 0.0);
            labelRect = NSMakeRect(0.0, 0.0, ENTITY_OUTLET_LABEL_WIDTH, frame.size.height);
        }
        else {
            pinPoint = NSMakePoint(0.0, 0.0);
            labelRect = NSMakeRect(ENTITY_OUTLET_LABEL_PADDING_FOR_INPUT, 0.0, ENTITY_OUTLET_LABEL_WIDTH, frame.size.height);
        }

        self.entity = anEntity;
        self.pin = [[[VJXBoardEntityPin alloc] initWithPin:thePin andPoint:pinPoint outlet:self] autorelease];
        self.output = isOutput;

        self.pinName = [[[NSTextField alloc] initWithFrame:labelRect] autorelease];
        [self.pinName setStringValue:self.pin.pin.name];
        [self.pinName setEditable:NO];
        [self.pinName setDrawsBackground:NO];
        [self.pinName setBordered:NO];
        [self.pinName setTextColor:[NSColor whiteColor]];
        [self.pinName setFont:[NSFont fontWithName:@"terminal" size:[NSFont smallSystemFontSize]]];
        [[self.pinName cell] setTruncatesLastVisibleLine:YES];

        if (isOutput)
            [self.pinName setAlignment:NSRightTextAlignment];

        [self addSubview:self.pinName];
        [self addSubview:self.pin];
    }
    return self;
}

- (void)dealloc
{
    self.pinName = nil;
    self.pin = nil;
    [super dealloc];
}

- (void)updateAllConnectorsFrames
{
    [pin updateAllConnectorsFrames];
}
@end

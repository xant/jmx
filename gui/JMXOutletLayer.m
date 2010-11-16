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
//  JMXBoardEntityOutlet.m by Igor Sutton on 9/8/10.
//

#import "JMXOutletLayer.h"
#import "JMXOutletLabelLayer.h"

@implementation JMXOutletLayer

@synthesize pin;
@synthesize output;
@synthesize entity;

- (id)initWithPin:(JMXPin *)thePin andPoint:(NSPoint)thePoint isOutput:(BOOL)isOutput entity:(JMXEntityLayer *)anEntity;
{
    if ((self = [super init]) != nil) {
        CGColorRef backgroundColor_ = CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 0.0f);
        self.backgroundColor = nil;
        self.borderWidth = 0.0f;
        self.borderColor = backgroundColor_;
        CFRelease(backgroundColor_);

        self.frame = JMXOutletLayerFrameCreate(thePoint);
        self.entity = anEntity;

        JMXOutletLabelLayer *labelLayer = [[[JMXOutletLabelLayer alloc] init] autorelease];
        labelLayer.string = thePin.name;
        labelLayer.borderWidth = 0.0f;
        labelLayer.backgroundColor = nil;
        labelLayer.fontSize = ENTITY_OUTLET_FONT_SIZE;
        
        CGPoint thePinPoint;

        if (isOutput) {
            thePinPoint = CGPointMake(self.frame.size.width - ENTITY_OUTLET_LABEL_PADDING_FOR_OUTPUT, 0.0f);
            labelLayer.frame = CGRectMake(0.0f, (ENTITY_OUTLET_HEIGHT - ENTITY_OUTLET_FONT_SIZE) / 2,
                                                 ENTITY_OUTLET_LABEL_WIDTH, self.frame.size.height);
            labelLayer.alignmentMode = kCAAlignmentRight;
        }
        else {
            thePinPoint = CGPointMake(ENTITY_OUTLET_LABEL_PADDING_FOR_INPUT, 0.0f);
            labelLayer.frame = CGRectMake(self.frame.size.width - ENTITY_OUTLET_LABEL_WIDTH, 0.0f,
                                          ENTITY_OUTLET_LABEL_WIDTH, self.frame.size.height);
        }
        self.pin = [[[JMXPinLayer alloc] initWithPin:thePin andPoint:NSPointFromCGPoint(thePinPoint) outlet:self] autorelease];
		[self addSublayer:labelLayer];
        [self addSublayer:pin];
        self.output = isOutput;
    }
    return self;
}

- (BOOL)containsPoint:(CGPoint)p
{
    return NO;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)updateAllConnectorsFrames
{
    [pin updateAllConnectorsFrames];
}
@end

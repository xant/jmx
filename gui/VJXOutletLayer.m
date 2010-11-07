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

#import "VJXOutletLayer.h"
#import "VJXOutletLabelLayer.h"

@implementation VJXOutletLayer

@synthesize pin;
@synthesize output;
@synthesize entity;

- (id)initWithPin:(VJXPin *)thePin andPoint:(NSPoint)thePoint isOutput:(BOOL)isOutput entity:(VJXEntityLayer *)anEntity;
{
    if ((self = [super init]) != nil) {
        CGColorRef backgroundColor_ = CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 0.0f);
        self.backgroundColor = NULL;
        self.borderWidth = 0.0f;
        self.borderColor = backgroundColor_;
        CFRelease(backgroundColor_);

        self.frame = VJXOutletLayerFrameCreate(thePoint);
        self.entity = anEntity;

        VJXOutletLabelLayer *labelLayer = [[[VJXOutletLabelLayer alloc] init] autorelease];
        labelLayer.string = thePin.name;
        labelLayer.borderWidth = 0.0f;
        labelLayer.backgroundColor = NULL;
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

        [self addSublayer:labelLayer];
        self.pin = [[[VJXPinLayer alloc] initWithPin:thePin andPoint:NSMakePoint(thePinPoint.x, thePinPoint.y) outlet:self] autorelease];
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

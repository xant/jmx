//
//  VJXBoardComponent.m
//  GraphRep
//
//  Created by Igor Sutton on 8/26/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
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

#import "VJXEntityLayer.h"
#import "VJXPinLayer.h"
#import "VJXOutletLayer.h"
#import "VJXEntityLabelLayer.h"

@implementation VJXEntityLayer

@synthesize entity;
@synthesize label;
@synthesize selected;
@synthesize outlets;
@synthesize inlets;
@synthesize board;

- (id)initWithEntity:(VJXEntity *)anEntity
{
    return [self initWithEntity:anEntity board:nil];
}

- (id)initWithEntity:(VJXEntity *)anEntity board:(VJXBoardView *)aBoard
{
    self = [super init];
    if (self) {
        self.geometryFlipped = YES;
        self.outlets = [NSMutableArray array];
        self.inlets = [NSMutableArray array];
        self.board = aBoard;
        self.entity = anEntity;
        self.selected = NO;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(inputPinAdded:)
                                                     name:@"VJXEntityInputPinAdded"
                                                   object:self.entity];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(inputPinRemoved:)
                                                     name:@"VJXEntityInputPinRemoved"
                                                   object:self.entity];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(outputPinAdded:)
                                                     name:@"VJXEntityOutputPinAdded"
                                                   object:self.entity];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(outputPinRemoved:)
                                                     name:@"VJXEntityOutputPinRemoved"
                                                   object:self.entity];

        [self setupLayer];
    }
    return self;
}

- (void)dealloc
{
    //NSLog(@"VJXEntityLayer dealloc called");
    [label release];

    [outlets release];

    [inlets release];
    if (entity) {
        if ([entity respondsToSelector:@selector(stop)])
            [entity performSelector:@selector(stop)];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"VJXEntityInputPinAdded" object:entity];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"VJXEntityInputPinRemoved" object:entity];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"VJXEntityOutputPinAdded" object:entity];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"VJXEntityOutputPinRemoved" object:entity];

        [[NSNotificationCenter defaultCenter] postNotificationName:@"VJXBoardEntityWasRemoved" object:entity];
        [entity release];
    }
    [super dealloc];
}

- (void)setupLayer
{
    CGColorRef backgroundColor = CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 0.5f);
    CGColorRef borderColor = CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 1.0f);
    CGColorRef shadowColor = CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 1.0f);
    self.backgroundColor = backgroundColor;
    self.borderColor = borderColor;
    self.shadowColor = shadowColor;
    self.borderWidth = 1.5f;
    self.cornerRadius = 5.0f;
    CFRelease(borderColor);
    CFRelease(backgroundColor);
    CFRelease(shadowColor);

    VJXEntityLabelLayer *labelLayer = [[VJXEntityLabelLayer alloc] init];
    labelLayer.string = self.entity.name;
    labelLayer.borderWidth = 0.0f;
    labelLayer.backgroundColor = NULL;
    labelLayer.fontSize = ENTITY_LABEL_FONT_SIZE;
    labelLayer.frame = CGRectMake(ENTITY_FRAME_WIDTH_PADDING, ENTITY_FRAME_HEIGHT_PADDING, ENTITY_LABEL_WIDTH, ENTITY_LABEL_HEIGHT);
    [self addSublayer:labelLayer];
    [labelLayer release];

    for (NSString *thePinName in [self.entity inputPins]) {
        VJXOutletLayer *outlet = [[VJXOutletLayer alloc] initWithPin:[self inputPinWithName:thePinName] andPoint:NSZeroPoint isOutput:NO entity:self];
        [self addSublayer:outlet];
        [self.inlets addObject:outlet];
        [outlet release];
    }

    for (NSString *thePinName in [self.entity outputPins]) {
        VJXOutletLayer *outlet = [[VJXOutletLayer alloc] initWithPin:[self outputPinWithName:thePinName] andPoint:NSZeroPoint isOutput:YES entity:self];
        [self addSublayer:outlet];
        [self.outlets addObject:outlet];
        [outlet release];
    }

    [self recalculateFrame];
    [self reorderOutlets];
    [self setNeedsDisplay];
}

- (void)recalculateFrame
{
    NSUInteger maxOutlets = MAX([self.inlets count], [self.outlets count]);
    CGFloat expectedFrameHeight = ((maxOutlets - 1) * ENTITY_OUTLET_MIN_SPACING) + (maxOutlets * ENTITY_OUTLET_HEIGHT) + ENTITY_LABEL_HEIGHT;
    CGRect f = self.frame;
    f.size = CGSizeMake(ENTITY_FRAME_WIDTH + (2 * ENTITY_FRAME_WIDTH_PADDING), expectedFrameHeight + (2 * ENTITY_FRAME_HEIGHT_PADDING));
    self.frame = f;
    [self setNeedsDisplay];
}

- (VJXPin *)outputPinWithName:(NSString *)aPinName
{
    return [self.entity outputPinWithName:aPinName];
}

- (VJXPin *)inputPinWithName:(NSString *)aPinName
{
    return [self.entity inputPinWithName:aPinName];
}

- (void)reorderOutlets
{
    [self setupPinsLayers:self.inlets startAtPoint:CGPointMake(self.bounds.origin.x, ENTITY_LABEL_HEIGHT) output:NO];
    [self setupPinsLayers:self.outlets startAtPoint:CGPointMake(self.bounds.size.width - ENTITY_OUTLET_WIDTH, ENTITY_LABEL_HEIGHT) output:YES];
}

- (void)setupPinsLayers:(NSArray *)pinLayers startAtPoint:(CGPoint)aPoint output:(BOOL)isOutput
{
    int y = aPoint.y;
    for (VJXOutletLayer *outlet in pinLayers) {
        CGPoint origin = CGPointMake(aPoint.x, y);
        y += ENTITY_OUTLET_MIN_SPACING + ENTITY_OUTLET_HEIGHT;
        CGRect aRect = outlet.frame;
        aRect.origin = origin;
        outlet.frame = aRect;
    }
}

- (void)inputPinAdded:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSString *pinName = [userInfo objectForKey:@"pinName"];
    VJXPin *aPin = [self inputPinWithName:pinName];
    VJXOutletLayer *outlet = [[VJXOutletLayer alloc] initWithPin:aPin andPoint:CGPointZero isOutput:NO entity:self];
    [self addSublayer:outlet];
    [self.inlets addObject:outlet];
    [outlet release];

    [self recalculateFrame];
    [self reorderOutlets];
}

- (void)inputPinRemoved:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSString *pinName = [userInfo objectForKey:@"pinName"];
    VJXOutletLayer *toRemove = nil;

    for (VJXOutletLayer *outlet in self.inlets) {
        if (outlet.pin.pin.name == pinName) {
            toRemove = outlet;
            break;
        }
    }

    if (toRemove) {
        [self.inlets removeObject:toRemove];
        [toRemove removeFromSuperlayer];
    }
}

- (void)outputPinAdded:(NSNotification *)notification
{
}

- (void)outputPinRemoved:(NSNotification *)notification
{
}

- (void)select
{
    CGColorRef borderColor_ = CGColorCreateGenericRGB(1.0f, 1.0f, 0.0f, 1.0f);
    self.borderColor = borderColor_;
    self.shadowColor = borderColor_;
    CFRelease(borderColor_);
}

- (void)unselect
{
    CGColorRef borderColor_ = CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 1.0f);
    self.borderColor = borderColor_;
    self.shadowColor = borderColor_;
    CFRelease(borderColor_);
}

- (void)setSelected:(BOOL)isSelected
{
    if (selected != isSelected)
        [self setNeedsDisplay];

    selected = isSelected;

    if (selected)
        [self select];
    else
        [self unselect];
}

- (void)toggleSelected
{
    self.selected = !self.selected;
}

- (NSString *)description
{
    return [self.entity description];
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    entity.name = [fieldEditor string];
    return YES;
}

- (id)copyWithZone:(NSZone *)aZone
{
    return [self retain];
}


id controlForVJXPinType(VJXPinType aType)
{
    NSString *name = [VJXPin nameforType:aType];
	if (name)
        return name;
    return @"None";
}

- (void)controlPin
{
	for (NSString *anInputPinName in self.entity.inputPins) {
		VJXInputPin *anInputPin = [self.entity inputPinWithName:anInputPinName];
		NSLog(@"name: %@, type: %@", anInputPin.name, controlForVJXPinType(anInputPin.type));
	}

}

- (void)setStringSelectionPin:(NSOutlineView *)outlineView
{
    NSPopUpButtonCell *item = [outlineView selectedCell];
    NSInteger row = [outlineView selectedRow];
    NSString *pinName = [outlineView itemAtRow:row];
    VJXInputPin *aPin = [self.entity inputPinWithName:pinName];
    if (aPin) {
        VJXOutputPin *vPin = [VJXPin pinWithName:@"setter" andType:kVJXStringPin forDirection:kVJXOutputPin ownedBy:nil withSignal:nil];
        [vPin connectToPin:aPin];
        [vPin deliverData:[item titleOfSelectedItem]];
    }
}

- (void)updateConnectors
{
    [outlets makeObjectsPerformSelector:@selector(updateAllConnectorsFrames)];
    [inlets makeObjectsPerformSelector:@selector(updateAllConnectorsFrames)];
}

@end

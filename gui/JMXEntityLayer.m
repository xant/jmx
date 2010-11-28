//
//  JMXBoardComponent.m
//  GraphRep
//
//  Created by Igor Sutton on 8/26/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
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

#import "JMXEntityLayer.h"
#import "JMXPinLayer.h"
#import "JMXOutletLayer.h"
#import "JMXEntityLabelLayer.h"

#define JMXInputOutletLayerCreate(x) [[[JMXOutletLayer alloc] initWithPin:(x) andPoint:NSZeroPoint isOutput:NO entity:self] autorelease]
#define JMXOutputOutletLayerCreate(x) [[[JMXOutletLayer alloc] initWithPin:(x) andPoint:NSZeroPoint isOutput:YES entity:self] autorelease]

@implementation JMXEntityLayer

@synthesize entity;
@synthesize label;
@synthesize selected;
@synthesize outlets;
@synthesize inlets;
@synthesize board;

- (id)initWithEntity:(JMXEntity *)anEntity
{
    return [self initWithEntity:anEntity board:nil];
}

- (id)initWithEntity:(JMXEntity *)anEntity board:(JMXBoardView *)aBoard
{
    self = [super init];
    if (self) {
        self.geometryFlipped = YES;
        self.outlets = [NSMutableArray array];
        self.inlets = [NSMutableArray array];
        self.board = aBoard;
        self.entity = anEntity;
        self.selected = NO;
        [self setupLayer];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(inputPinAdded:)
                                                     name:@"JMXEntityInputPinAdded"
                                                   object:self.entity];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(inputPinRemoved:)
                                                     name:@"JMXEntityInputPinRemoved"
                                                   object:self.entity];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(outputPinAdded:)
                                                     name:@"JMXEntityOutputPinAdded"
                                                   object:self.entity];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(outputPinRemoved:)
                                                     name:@"JMXEntityOutputPinRemoved"
                                                   object:self.entity];
    }
    return self;
}

- (void)dealloc
{
    //NSLog(@"JMXEntityLayer dealloc called");
    [label release];

    [outlets release];

    [inlets release];
    if (entity) {
        if ([entity respondsToSelector:@selector(stop)])
            [entity performSelector:@selector(stop)];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"JMXEntityInputPinAdded" object:entity];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"JMXEntityInputPinRemoved" object:entity];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"JMXEntityOutputPinAdded" object:entity];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"JMXEntityOutputPinRemoved" object:entity];

        [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXBoardEntityWasRemoved" object:entity];
        [entity release];
    }
    [super dealloc];
}

JMXEntityLabelLayer *JMXEntityLabelLayerCreate(NSString *name) {
    JMXEntityLabelLayer *labelLayer = [[JMXEntityLabelLayer alloc] init];
    labelLayer.string = name;
    labelLayer.borderWidth = 0.0f;
    labelLayer.backgroundColor = NULL;
    labelLayer.fontSize = ENTITY_LABEL_FONT_SIZE;
    labelLayer.frame = JMXEntityLabelFrameCreate();
    return [labelLayer autorelease];
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

    [self addSublayer:JMXEntityLabelLayerCreate(self.entity.name)];
/*
    for (NSString *thePinName in [self.entity inputPins]) {
        JMXOutletLayer *outlet = JMXInputOutletLayerCreate([self inputPinWithName:thePinName]);
        [self addSublayer:outlet];
        [self.inlets addObject:outlet];
    }

    for (NSString *thePinName in [self.entity outputPins]) {
        JMXOutletLayer *outlet = JMXOutputOutletLayerCreate([self inputPinWithName:thePinName]);
        [self addSublayer:outlet];
        [self.outlets addObject:outlet];
    }
    [self recalculateFrame];
 */
}

- (void)recalculateFrame
{
    NSUInteger maxOutlets = MAX([self.inlets count], [self.outlets count]);
    CGRect f = self.frame;
    f.size = JMXEntityFrameSize(maxOutlets);
    self.frame = f;
}

- (JMXPin *)outputPinWithName:(NSString *)aPinName
{
    return [self.entity outputPinWithName:aPinName];
}

- (JMXPin *)inputPinWithName:(NSString *)aPinName
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
    for (JMXOutletLayer *outlet in pinLayers) {
        CGRect aRect = outlet.frame;
        aRect.origin = CGPointMake(aPoint.x, y);
        outlet.frame = aRect;
        y += ENTITY_OUTLET_OFFSET;
    }
}

- (void)inputPinAdded:(NSNotification *)notification
{
    JMXOutletLayer *outlet = JMXInputOutletLayerCreate([[notification userInfo] objectForKey:@"pin"]);
    [self addSublayer:outlet];
    [self.inlets addObject:outlet];
    [self recalculateFrame];
    [self reorderOutlets];
}

- (void)inputPinRemoved:(NSNotification *)notification
{
    NSString __block *pinName = [[notification userInfo] objectForKey:@"pinName"];
    NSUInteger index = [self.inlets indexOfObjectPassingTest:^(id obj, NSUInteger index, BOOL *stop) {
        return [((JMXOutletLayer *)obj).pin.pin.name isEqualToString:pinName];
    }];
    [[self.inlets objectAtIndex:index] removeFromSuperlayer];
    [self.inlets removeObjectAtIndex:index];
    [self recalculateFrame];
    [self reorderOutlets];
}

- (void)outputPinAdded:(NSNotification *)notification
{
    JMXOutletLayer *outlet = JMXOutputOutletLayerCreate([[notification userInfo] objectForKey:@"pin"]);
    [self addSublayer:outlet];
    [self.outlets addObject:outlet];
    [self recalculateFrame];
    [self reorderOutlets];
}

- (void)outputPinRemoved:(NSNotification *)notification
{
    NSString __block *pinName = [[notification userInfo] objectForKey:@"pinName"];
    NSUInteger index = [self.outlets indexOfObjectPassingTest:^(id obj, NSUInteger index, BOOL *stop) {
        return [((JMXOutletLayer *)obj).pin.pin.name isEqualToString:pinName];
    }];
    [[self.outlets objectAtIndex:index] removeFromSuperlayer];
    [self.outlets removeObjectAtIndex:index];
    [self recalculateFrame];
    [self reorderOutlets];
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

- (id)copyWithZone:(NSZone *)aZone
{
    return [self retain];
}

id controlForJMXPinType(JMXPinType aType)
{
    NSString *name = [JMXPin nameforType:aType];
    if (name)
        return name;
    return @"None";
}

- (void)controlPin
{
    for (NSString *anInputPinName in self.entity.inputPins) {
        JMXInputPin *anInputPin = [self.entity inputPinWithName:anInputPinName];
        NSLog(@"name: %@, type: %@", anInputPin.name, controlForJMXPinType(anInputPin.type));
    }

}

- (void)updateConnectors
{
    [outlets makeObjectsPerformSelector:@selector(updateAllConnectorsFrames)];
    [inlets makeObjectsPerformSelector:@selector(updateAllConnectorsFrames)];
}

@end

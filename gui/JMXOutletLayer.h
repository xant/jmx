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
//  JMXBoardEntityOutlet.h by Igor Sutton on 9/8/10.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "JMXPinLayer.h"
#import "JMXEntityLayer.h"
#import "JMXGUIConstants.h"

@class JMXPinLayer;
@class JMXEntityLayer;

@interface JMXOutletLayer : CALayer
{
    JMXPinLayer *pin;
    JMXEntityLayer *entity;
    BOOL output;
}

@property (nonatomic, assign) JMXEntityLayer *entity;
@property (nonatomic, assign) JMXPinLayer *pin;
@property (nonatomic, assign) BOOL output;

- (id)initWithPin:(JMXPin *)thePin andPoint:(NSPoint)thePoint isOutput:(BOOL)isOutput entity:(JMXEntityLayer *)anEntity;
- (void)updateAllConnectorsFrames;

@end

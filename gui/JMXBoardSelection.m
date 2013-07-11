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
//  JMXBoardSelection.m by Igor Sutton on 9/9/10.
//

#import "JMXBoardSelection.h"


@implementation JMXBoardSelection

- (void)drawRect:(NSRect)dirtyRect
{
    
    [[NSColor colorWithDeviceRed:0.0 green:0.0 blue:1.0 alpha:0.2] setFill];
    [[NSColor colorWithDeviceRed:0.0 green:0.0 blue:1.0 alpha:1.0] setStroke];

    NSBezierPath *thePath = [[NSBezierPath alloc] init];
    NSAffineTransform *transform = [[[NSAffineTransform alloc] init] autorelease];
    [transform translateXBy:0.5 yBy:0.5];
    [thePath transformUsingAffineTransform:transform];
    [thePath setLineWidth:2.0];
    [thePath appendBezierPathWithRect:[self bounds]];
    [thePath stroke];
    [thePath fill];
    
    [thePath release];
}

@end

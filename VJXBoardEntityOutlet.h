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
//  VJXBoardEntityOutlet.h by Igor Sutton on 9/8/10.
//

#import <Cocoa/Cocoa.h>
#import "VJXBoardEntityPin.h"

@interface VJXBoardEntityOutlet : NSView
{
    VJXBoardEntityPin *pin;
    NSTextField *pinName;
    BOOL output;
}

@property (nonatomic,retain) VJXBoardEntityPin *pin;
@property (nonatomic,retain) NSTextField *pinName;
@property (nonatomic,assign) BOOL output;

- (id)initWithPin:(VJXPin *)thePin andPoint:(NSPoint)thePoint isOutput:(BOOL)isOutput;
- (void)updateAllConnectorsFrames;

@end

//
//  VJXBoardDelegate.h
//  VeeJay
//
//  Created by Igor Sutton on 8/27/10.
//  Copyright 2010 Dyne.org. All rights reserved.
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

#import <Cocoa/Cocoa.h>
#import "VJXBoard.h"


@interface VJXBoardDelegate : NSObject {
    VJXBoard *board;
}

@property (nonatomic,assign) IBOutlet VJXBoard *board;

- (IBAction)addEntity:(id)sender;

- (IBAction)addMovieLayer:(id)sender;
- (IBAction)addImageLayer:(id)sender;
- (IBAction)addOutputScreen:(id)sender;
- (IBAction)addMixerLayer:(id)sender;

+ (void)setSharedBoard:(id)aBoard;
+ (id)sharedBoard;

@end

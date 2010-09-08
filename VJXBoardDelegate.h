//
//  VJXBoardDelegate.h
//  VeeJay
//
//  Created by Igor Sutton on 8/27/10.
//  Copyright 2010 Dyne.org. All rights reserved.
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

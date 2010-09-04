//
//  VJMovieLayer.h
//  MoviePlayerC
//
//  Created by Igor Sutton on 8/5/10.
//  Copyright (c) 2010 StrayDev.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import "VJXLayer.h"

@interface VJXMovieLayer : VJXLayer {
    QTMovie *movie;
    NSUInteger timeScale;
    NSString *moviePath;
    float lastTimeValue;

    BOOL paused;
    BOOL stopped;
}

@property (nonatomic, retain) QTMovie *movie;
@property (nonatomic, copy) NSString *moviePath;
@property (nonatomic, assign) BOOL paused;
@property (nonatomic, assign) BOOL stopped;
@property (nonatomic, assign) float lastTimeValue;

- (void)loadMovie;

@end

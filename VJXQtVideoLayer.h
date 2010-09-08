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

@interface VJXQtVideoLayer : VJXLayer {
    QTMovie *movie;
    NSString *moviePath;

    BOOL paused;
    BOOL repeat;
}

@property (retain) QTMovie *movie;
@property (copy) NSString *moviePath;
@property (assign) BOOL paused;
@property (assign) BOOL repeat;

- (BOOL)open:(NSString *)file;

@end

//
//  MoviePlayerOpenGLView.h
//  MoviePlayerC
//
//  Created by Igor Sutton on 8/5/10.
//  Copyright (c) 2010 StrayDev.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuickTime/QuickTime.h>
#import <QTKit/QTKit.h>
#import <OpenGL/OpenGL.h>

@interface VJXOpenGLView : NSOpenGLView {
    CIImage *currentFrame;
    CIContext *ciContext;
    NSRecursiveLock *lock;

    BOOL needsReShape;
}

@property (assign) CIImage *currentFrame;

@end

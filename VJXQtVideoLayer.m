//
//  VJMovieLayer.m
//  MoviePlayerC
//
//  Created by Igor Sutton on 8/5/10.
//  Copyright (c) 2010 StrayDev.com. All rights reserved.
//

#import "VJXQtVideoLayer.h"


@implementation VJXQtVideoLayer

@synthesize movie, moviePath, paused, repeat;

- (id)init
{
    if ((self = [super init])) {
        movie = nil;
        moviePath = nil;
        repeat = YES;
        paused = NO;
        [self registerInputPin:@"repeat" withType:kVJXNumberPin andSelector:@"setRepeat:"];
        [self registerInputPin:@"paused" withType:kVJXNumberPin andSelector:@"setPaused:"];
    }

    return self;
}

- (void)loadMovie
{
    if (moviePath != nil) {
        NSError *error;
        NSLog(@"moviePath: %@", moviePath);
        if (movie)
            [movie release];
        movie = [[QTMovie movieWithFile:moviePath error:&error] retain];
        if (!movie) {
            NSLog(@"Got error: %@", error);
        }
        NSLog(@"movie: %@", movie);
        NSArray* videoTracks = [movie tracksOfMediaType:QTMediaTypeVideo];
        QTTrack* firstVideoTrack = [videoTracks objectAtIndex:0];
        QTMedia* media = [firstVideoTrack media];
        QTTime qtTimeDuration = [[media attributeForKey:QTMediaDurationAttribute] QTTimeValue];
        long sampleCount = [[media attributeForKey:QTMediaSampleCountAttribute] longValue];
        // we can set the frequency to be exactly the same as fps ... since it's useles
        // to have an higher signaling frequency in the case of an existing movie. 
        // In any case we won't have more 'unique' frames than the native movie fps ... so if signaling 
        // the frames more often we will just send the same image multiple times (wasting precious cpu time)
        self.frequency = [NSNumber numberWithDouble:sampleCount/(qtTimeDuration.timeValue/qtTimeDuration.timeScale)];
        self.fps = self.frequency;
    }
}

- (void)dealloc {
    [movie release];
    [super dealloc];
}

- (void)tick:(uint64_t)timeStamp
{
    QTTime now = [movie currentTime];
    @synchronized(self) {
        if (!paused) {
            uint64_t delta = previousTimeStamp
                           ? (timeStamp - previousTimeStamp) / 1e9 * now.timeScale
                           : now.timeScale / [fps doubleValue];
            // Calculate the next frame we need to provide.
            now.timeValue += delta;

            if (QTTimeCompare(now, [movie duration]) == NSOrderedAscending) {
                [movie setCurrentTime:now];
            } else { // the movie is ended
                if (repeat) { // check if we need to rewind and re-start extracting frames
                    [movie gotoBeginning];
                } else {
                    [self stop];
                    self.currentFrame = nil; // XXX - perhaps we should return a black frame instead of nil 
                    return [super tick:timeStamp]; // we still want to propagate the signal
                }
            }
        
            // Setup the attrs dictionary. 
            // We want to get back a CIImage object of the proper size.
            NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSValue valueWithSize:self.size.nsSize],
                                   QTMovieFrameImageSize,
                                   QTMovieFrameImageTypeCIImage,
                                   QTMovieFrameImageType,
                                   [NSNumber numberWithBool:TRUE],
                                   QTMovieFrameImageSessionMode,
                                   nil];

            // Get our CIImage.
            // TODO: Implement error handling.
            // XXX - and check why requested framesize is not honored
            self.currentFrame = [movie frameImageAtTime:now withAttributes:attrs error:nil];
        } 
    }
    [super tick:timeStamp]; // let super notify output pins
}

@end

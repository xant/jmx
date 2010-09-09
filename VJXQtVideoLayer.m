//
//  VJMovieLayer.m
//  MoviePlayerC
//
//  Created by Igor Sutton on 8/5/10.
//  Copyright (c) 2010 StrayDev.com. All rights reserved.
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
        
        NSSize defaultLayerSize = { 640, 480 };
        size = [[VJXSize sizeWithNSSize:defaultLayerSize] retain];

    }

    return self;
}

- (BOOL)open:(NSString *)file
{
    if (file != nil) {
        NSError *error;
        self.moviePath = file;
        NSLog(@"moviePath: %@", moviePath);
        if (movie)
            [movie release];
        movie = [[QTMovie movieWithFile:moviePath error:&error] retain];
        if (!movie) {
            NSLog(@"Got error: %@", error);
            return NO;
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
        if (sampleCount > 1) // check if we indeed have a sequence of frames
            self.frequency = [NSNumber numberWithDouble:sampleCount/(qtTimeDuration.timeValue/qtTimeDuration.timeScale)];
        else // or if it's just a still image, set the frequency to 1 sec
            self.frequency = [NSNumber numberWithDouble:1]; // XXX
            

        self.fps = self.frequency;
        return YES;
    }
    return NO;
}

- (void)dealloc {
    if (movie)
        [movie release];
    [super dealloc];
}

- (void)tick:(uint64_t)timeStamp
{
    if (movie) {
        QTTime now = [movie currentTime];
        @synchronized(self) {
            if (!paused) {
                if (currentFrame) {
                    [currentFrame release];
                    currentFrame = nil;
                }
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
                        now.timeValue = 0;
                    } else {
                        [self stop];
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
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
                                       [NSNumber numberWithBool:TRUE],
                                       QTMovieFrameImageSessionMode,
#endif
                                       nil];

                // Get our CIImage.
                // TODO: Implement error handling.
                // XXX - and check why requested framesize is not honored
                CIImage *frame = [movie frameImageAtTime:now withAttributes:attrs error:nil];
                if (frame)
                    currentFrame = [frame retain];
            } 
        }
    }
    [super tick:timeStamp]; // let super notify output pins
}

#pragma mark -

- (NSString *)displayName
{
    return [NSString stringWithFormat:@"%@", self.moviePath];
}

@end

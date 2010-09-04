//
//  VJMovieLayer.m
//  MoviePlayerC
//
//  Created by Igor Sutton on 8/5/10.
//  Copyright (c) 2010 StrayDev.com. All rights reserved.
//

#import "VJXMovieLayer.h"


@implementation VJXMovieLayer

@synthesize movie, moviePath, paused, stopped, lastTimeValue;

- (id)init
{
    if ((self = [super init])) {
        movie = nil;
        moviePath = nil;
        timeScale = 600;
        previousTimeStamp = 0;
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
    }
}

- (void)dealloc {
    [movie release];
    [super dealloc];
}

- (void)tick:(uint64_t)timeStamp
{
    QTTime now = [movie currentTime];
    if (![self paused]) {
        @synchronized(self) {
            // Find out the difference between the last time an image was
            // requested and the current time. Since we prevent this to be
            // called too often, we should get approximatelly 24fps.
            
            //uint64_t delta = (previousTimeStamp > 0 ? timeStamp - previousTimeStamp : 0);

            // Calculate the position of the next frame, based on the pre-
            // calculated delta and the timeScale we provide. Please note
            // the delta is in nanoseconds, hence the 1e9.
            // now.timeValue += (delta * now.timeScale) / 1e9;

            // Set the timeValue to the last timeValue we've seen, since this isn't a
            // real video stream, and we can "pause" the video.
            now.timeValue = lastTimeValue;

            // Calculate the next frame - I don't know yet how to do this.
            now.timeValue += now.timeScale / 23; // 24fps

            // Remember the timeValue.
            lastTimeValue = now.timeValue;

            // Move the frame to the time we specified, so we don't need to
            // keep track of the movie's position ourselves.
            [movie setCurrentTime:now];

            // Store the the current timeStamp->hostTime as our reference
            // for the next call.
            previousTimeStamp = timeStamp;

            // Setup the attrs dictionary. We want to get back from frameImageAtTime:withAttributes:error:
            // a CIImage object.
            NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                   QTMovieFrameImageTypeCIImage,
                                   QTMovieFrameImageType,
                                   [NSNumber numberWithBool:TRUE],
                                   QTMovieFrameImageSessionMode,
                                   nil];

            // Get our CIImage.
            // TODO: Implement error handling.
            CIImage *newFrame = [movie frameImageAtTime:now withAttributes:attrs error:nil];

            CIImage *transformedFrame = nil;

            if (newFrame) {
                // Apply some basic filters.
                CIFilter *colorFilter = [CIFilter filterWithName:@"CIColorControls"];
                [colorFilter setDefaults];
                [colorFilter setValue:saturation forKey:@"inputSaturation"];
                [colorFilter setValue:brightness forKey:@"inputBrightness"];
                [colorFilter setValue:contrast forKey:@"inputContrast"];
                [colorFilter setValue:newFrame forKey:@"inputImage"];

                // Return the new frame. It should be retained by the user.
                transformedFrame = [colorFilter valueForKey:@"outputImage"];
            }
            self.currentFrame = transformedFrame;
        }
    }
    return [super tick:timeStamp]; // let super notify output pins
}

@end

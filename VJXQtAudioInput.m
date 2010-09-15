//
//  VJXQtAudioInput.m
//  VeeJay
//
//  Created by xant on 9/15/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXQtAudioInput.h"


@implementation VJXQtAudioInput

- (id)init
{
    if (self = [super init]) {
        
    }
    return self;
}
/*
- (BOOL)open:(NSString *)file
{
    OSStatus	err = noErr;
	
    if (file != nil) {
        NSError *error;
        moviePath = [file retain];
        NSLog(@"moviePath: %@", moviePath);
        @synchronized(self) {
            if (movie)
                [movie release];
            // Setter already releases and retains where appropriate.
            movie = [[QTMovie movieWithFile:moviePath error:&error] retain];
            
            if (!movie) {
                NSLog(@"Got error: %@", error);
                return NO;
            }
            
            NSLog(@"movie: %@", movie);
            NSArray* audioTracks = [movie tracksOfMediaType:QTMediaTypeSound];
            QTTrack* firstAudioTrack = [audioTracks objectAtIndex:0];
            QTMedia* media = [firstVideoTrack media];
            QTTime qtTimeDuration = [[media attributeForKey:QTMediaDurationAttribute] QTTimeValue];
            long sampleCount = [[media attributeForKey:QTMediaSampleCountAttribute] longValue];
            // we can set the frequency to be exactly the same as fps ... since it's useles
            // to have an higher signaling frequency in the case of an existing movie. 
            // In any case we won't have more 'unique' frames than the native movie fps ... so if signaling 
            // the frames more often we will just send the same image multiple times (wasting precious cpu time)
            if (sampleCount > 1) // check if we indeed have a sequence of frames
                self.frequency = [NSNumber numberWithDouble:(sampleCount+1)/(qtTimeDuration.timeValue/qtTimeDuration.timeScale)];
            else // or if it's just a still image, set the frequency to 1 sec
                self.frequency = [NSNumber numberWithDouble:1]; // XXX
            
            // set the layer size to the native movie size
            // scaling is a quite expensive operation and the user 
            // must be aware he is doing that (so better waiting for him
            // to set a different layer size by using the proper input pin)
            NSSize movieSize = [firstVideoTrack apertureModeDimensionsForMode:@"QTMovieApertureModeClean"];
            size = [[VJXSize sizeWithNSSize:movieSize] retain];
            self.fps = self.frequency;
            NSArray *path = [moviePath componentsSeparatedByString:@"/"];
            self.name = [path lastObject];
        }   
        
        // Movie extraction begin: Open an extraction session
        err = MovieAudioExtractionBegin([movie quickTimeMovie], 0, &extractionRef);
        require(err == noErr, bail);	
	
	// If we need to extract all discrete channels, set that property
	if (discrete)
	{
        err = MovieAudioExtractionSetProperty(&extractionRef,
                                              kQTPropertyClass_MovieAudioExtraction_Movie,
                                              kQTMovieAudioExtractionMoviePropertyID_AllChannelsDiscrete,
                                              sizeof (discrete), 
                                              &discrete);
        require(err == noErr, bail);	
	}
	// Set the extraction ASBD
	err = MovieAudioExtractionSetProperty(*extractionRefPtr,
                                          kQTPropertyClass_MovieAudioExtraction_Audio,
                                          kQTMovieAudioExtractionAudioPropertyID_AudioStreamBasicDescription,
                                          sizeof (asbd), &asbd);
	require(err == noErr, bail);	
    
	// Set the output layout, if supplied
	if (*layout)
	{
		err = MovieAudioExtractionSetProperty(*extractionRefPtr,
                                              kQTPropertyClass_MovieAudioExtraction_Audio,
                                              kQTMovieAudioExtractionAudioPropertyID_AudioChannelLayout,
                                              *layoutSizePtr, *layout);
        require(err == noErr, bail);	
	}
    
	// Set the extraction start time.  The duration will be determined by how much is pulled.
	err = MovieAudioExtractionSetProperty(*extractionRefPtr,
                                          kQTPropertyClass_MovieAudioExtraction_Movie,
                                          kQTMovieAudioExtractionMoviePropertyID_CurrentTime,
                                          sizeof(TimeRecord), &startTime);
        return YES;
    }
    return NO; 
bail:
	// If error, close the extraction session
	if (err != noErr)
	{
		if (*extractionRefPtr != nil)
			MovieAudioExtractionEnd(*extractionRefPtr);
	}	
	return err;
    
}
*/
@end

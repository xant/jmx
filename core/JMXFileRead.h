//
//  JMXFileRead.h
//  JMX
//
//  Created by xant on 10/2/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//
/*!
 @header JMXFileRead.h
 @abstract define a formal protocol for entities which makes use of an input file
 */

#import <Cocoa/Cocoa.h>

/*!
 @protocol JMXFileRead
 @abstract formal protocol for entities using input files (like JMXScriptFileEntity, JMXAudioFileEntity, JMXImageEntity and JMXQtMovieEntity)
 */
@protocol JMXFileRead

@required
/*!
 @method supportedFileTypes
 @abstract class method which returns an NSArray containing all allowed/supported file extensions 
 */
+ (NSArray *)supportedFileTypes;
/*!
 @method open
 @abstract open an input file
 @param file NSString containing the path (or the url) of the file to open
 @return YES if the file has been opened successfully, NO otherwise
 */
- (BOOL)open:(NSString *)file;
/*!
 @method close
 @abstract close current file (if any has been already opened)
 */
- (void)close;

@optional

- (void)seekTime:(int64_t)timeOffset;
- (void)seekAbsoluteTime:(int64_t)timeOffset;
- (void)seekFrame:(uint64_t)frameNum;

@end

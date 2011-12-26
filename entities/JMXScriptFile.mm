//
//  JMXScriptFile.m
//  JMX
//
//  Created by xant on 11/4/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "JMXScriptFile.h"
#import "JMXScript.h"
#import "JMXThreadedEntity.h"

@implementation JMXScriptFile

@synthesize path;

+ (NSArray *)supportedFileTypes
{
    return [NSArray arrayWithObjects:@"js", @"javascript", nil];
}

- (id)init
{
    self = [super init];
    if (self) {
        path = nil;
        self.label = @"JMXScriptFile";
        self.frequency = [NSNumber numberWithDouble:1.0];
        JMXThreadedEntity *threadedEntity = [JMXThreadedEntity threadedEntity:self];
        if (threadedEntity)
            return threadedEntity;
    }
    [self dealloc];
    return nil;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)setPath:(NSString *)newPath
{
    if (path)
        [self close];
    if ([self open:newPath]) {
        path = [newPath copy];
        self.label = path;
    } else {
        NSLog(@"JMXScriptFile::setPath(): Can't open file %@", newPath);
    }
}

- (BOOL)open:(NSString *)newPath
{
    @synchronized(self) {
        NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:newPath];
        if (fh) {
            NSData *data = [fh readDataToEndOfFile];
            self.code = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [NSString stringWithCharacters:(const unichar *)[data bytes] length:[data length]];
            self.label = [[newPath componentsSeparatedByString:@"/"] lastObject];
        }
    }
    return YES;
}

- (void)close
{
    if (path)
        [path release];
    path = nil;
    if (self.code)
        self.code = nil;
}

- (void)tick:(uint64_t)timeStamp
{
    if (!self.quit) {
        self.quit = YES; // we want to stop the thread as soon as the script exits
        if (self.code)
            [self exec];
        else
            NSLog(@"JMXScriptEntity::tick(): No script to run");
        //[self resetContext];
    }
    
}

@end

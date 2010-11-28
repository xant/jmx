//
//  JMXScriptFile.m
//  JMX
//
//  Created by xant on 11/4/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "JMXScriptFile.h"
#import "JMXScript.h"

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
        self.name = @"JMXScript";
    }
    return self;
}

- (void)setPath:(NSString *)newPath
{
    if (path)
        [self close];
    if ([self open:newPath]) {
        path = [newPath copy];
        self.name = path;
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
            self.name = [[newPath componentsSeparatedByString:@"/"] lastObject];
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

- (void)runScript
{
}
@end

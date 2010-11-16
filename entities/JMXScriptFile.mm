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
    }
    return self;
}

- (void)setPath:(NSString *)newPath
{
    if (path)
        [self close];
    if ([self open:newPath])
        path = [newPath copy];
    else
        NSLog(@"JMXScriptFile::setPath(): Can't open file %@", newPath);
}

- (BOOL)open:(NSString *)newPath
{
    @synchronized(self) {
        self.code = [NSString stringWithFormat:@"include('%@');", newPath];

        self.name = [[path componentsSeparatedByString:@"/"] lastObject];
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

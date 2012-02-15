//
//  main.m
//  MoviePlayerD
//
//  Created by Igor Sutton on 8/24/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JMXGlobals.h>

int verbose = LOG_INFO;

int main(int argc, char *argv[])
{
    openlog("JMX", LOG_PERROR, LOG_USER);
    NSString *blah = nil;
    return NSApplicationMain(argc,  (const char **) argv);
}

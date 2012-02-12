//
//  MoviePlayerDAppDelegate.h
//  MoviePlayerD
//
//  Created by Igor Sutton on 8/24/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
//
//  This file is part of JMX
//
//  JMX is free software: you can redistribute it and/or modify
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
//  along with JMX.  If not, see <http://www.gnu.org/licenses/>.
//

#import <Cocoa/Cocoa.h>

#ifndef __JMXAppDelegate_H__
#define __JMXAppDelgate_H__

#if MAC_OS_X_VERSION_10_6
@interface JMXAppDelegate : NSObject <NSApplicationDelegate> {
#else
@interface JMXAppDelegate : NSObject {
#endif
    NSWindow *window;
    NSTableView *layersTableView;
    BOOL batchMode;
    NSTextView *consoleView;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTableView *layersTableView;
@property (readonly) BOOL batchMode;
@property (assign) NSTextView *consoleView;

- (void)logMessage:(NSString *)message, ...;

@end

#endif
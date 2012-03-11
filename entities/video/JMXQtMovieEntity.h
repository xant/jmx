//
//  JMXQtMovieLayer.h
//  JMX
//
//  Created by Igor Sutton on 8/5/10.
//  Copyright (c) 2010 StrayDev.com. All rights reserved.
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

#import "JMXVideoEntity.h"
#import "JMXFileRead.h"
#ifndef __x86_64
#import <QuickTime/QuickTime.h>
#endif
@class QTMovie;

@interface JMXQtMovieEntity : JMXVideoEntity <JMXFileRead> {
@private
    QTMovie *movie;
    NSString *moviePath;
    uint64_t movieFrequency;
    BOOL paused;
    BOOL repeat;
    double sampleCount;
    double duration;
    int64_t seekOffset;
    int64_t absoluteTime;

#ifndef __x86_64
    QTVisualContextRef    qtVisualContext;        // the context the movie is playing in
#endif
}

@property (copy) NSString *moviePath;
@property (assign) BOOL paused;
@property (assign) BOOL repeat;
@property (readonly) double duration;
@property (readonly) double sampleCount;
@end

JMXV8_DECLARE_NODE_CONSTRUCTOR(JMXQtMovieEntity);

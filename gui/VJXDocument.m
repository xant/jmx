//
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
//  VJXDocument.m by Igor Sutton on 9/15/10.
//

#import "VJXDocument.h"


@implementation VJXDocument

@synthesize entities;

- (id)init
{
    if ((self = [super init]) != nil) {
        entities = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSString *)windowNibName
{
    return @"VJXDocument";
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    NSMutableData *data;
    NSKeyedArchiver *archiver;
    
    data = [NSMutableData data];
    archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    
    [archiver encodeObject:entities forKey:@"Entities"];
    [archiver finishEncoding];
    [archiver release];
    
    return data;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    NSKeyedUnarchiver *unarchiver;
    
    unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    entities = [[unarchiver decodeObjectForKey:@"Entities"] retain];
    [unarchiver finishDecoding];
    [unarchiver release];
    return YES;
}

@end

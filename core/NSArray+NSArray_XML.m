//
//  NSArray+NSArray_XML.m
//  JMX
//
//  Created by Andrea Guzzo on 12/26/11.
//  Copyright (c) 2011 Dyne.org. All rights reserved.
//

#import "NSArray+NSArray_XML.h"

@implementation NSArray (NSArray_XML)
- (void)_XMLStringWithOptions:(NSUInteger)options appendingToString:(NSMutableString *)string
{
    for (NSXMLElement *element in self) {
        [element _XMLStringWithOptions:options appendingToString:string];
    }
}
@end

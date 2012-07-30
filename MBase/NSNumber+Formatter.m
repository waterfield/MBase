//
//  NSNumber+Formatter.m
//  MBase
//
//  Created by Jason Whitehorn on 7/30/12.
//  Copyright (c) 2012 Waterfield Technologies. All rights reserved.
//

#import "NSNumber+Formatter.h"

@implementation NSNumber (Formatter)

- (NSString *) toCurrencyString{
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    return [formatter stringFromNumber:self];
    
}

@end

//
//  NSData+base64.h
//  iClone
//
//  Created by Jason Whitehorn on 7/18/12.
//  Copyright (c) 2012 Waterfield Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (base64)

+ (NSString *) base64StringFromData:(NSData *)data length:(int)length;
- (NSString *) base64Encode;

@end

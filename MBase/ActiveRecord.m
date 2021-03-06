//
//  ActiveRecord.m
//  MBase
//
//  Created by Jason Whitehorn on 7/26/12.
//  Copyright (c) 2012-2013 Waterfield Technologies. All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "ActiveRecord.h"
#import "NSString+ActiveSupportInflector.h"

@interface ActiveRecord()

@end

@implementation ActiveRecord

+ (void) getById:(int)objId withCallback:(void(^)(id))callback{
    NSString *className = NSStringFromClass(self.class);
    NSString *path = [NSString stringWithFormat:@"%@/%i", [[className pluralizeString] lowercaseString], objId];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *result = [self objectsFromPath:path];
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(result);
        });
    });
}

+ (void) getAllWithCallback:(void (^)(id))callback {
    NSString *className = NSStringFromClass(self.class);
    NSString *path = [NSString stringWithFormat:@"%@", [[className pluralizeString] lowercaseString]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *result = [self objectsFromPath:path];
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(result);
        });
    });
}

+ (void) create:(NSDictionary *)params withCallback:(void (^)(id))callback {
    NSString *className = [NSStringFromClass(self.class) lowercaseString];
    NSString *path = [NSString stringWithFormat:@"%@", [[className pluralizeString] lowercaseString]];
    
    params = [params objectForKey:className] ? params : @{className : params};
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *newData = [self.class postData:params toPath:path];
        id object = [[self alloc] initWithDictionary:newData];
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(object);
        });
    });
}

@end

//
//  MBase.h
//  MBase
//
//  Created by Jason Whitehorn on 7/26/12.
//  Copyright (c) 2012 Waterfield Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBase : NSObject

- (id) initWithDictionary:(NSDictionary *)dictionary;

+ (NSString *) authorizationWithUsername:(NSString *)username andPassword:(NSString *)password;

+ (id) postData:(NSDictionary *)data toUrl:(NSString *)url;
+ (id) postData:(NSDictionary *)data toUrl:(NSString *)url withAuthorization:(NSString *)authorization;
+ (id) getDataFromUrl:(NSString *)url;
+ (id) getDataFromUrl:(NSString *)url withAuthorization:(NSString *)authorization;

@end
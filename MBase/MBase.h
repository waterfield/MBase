//
//  MBase.h
//  MBase
//
//  Created by Jason Whitehorn on 7/26/12.
//  Copyright (c) 2012 Waterfield Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

#define _belongsTo @"belongsTo"
#define _foreignKey @"foreignKey"
#define _hasMany @"hasMany"
#define with_aliases(mapping) - (NSDictionary *) msbaseAliases { return mapping; }
#define with_relationships(mapping) - (NSArray *) mbaseRelationships { return mapping; }

@interface MBase : NSObject <NSCoding>

- (id) initWithDictionary:(NSDictionary *)dictionary;
- (id) initWithContentFromPath:(NSString *)path;
- (id) initWithContentFromPath:(NSString *)path withAuthorization:(NSString *)authorization;

- (id) inspect;

+ (NSArray *) objectsFromPath:(NSString *)path;
+ (NSArray *) objectsFromPath:(NSString *)path withAuthorization:(NSString *)authorization;

+ (NSArray *) cachedObjectsFromPath:(NSString *)path withCallback:(void (^)(id))callback;
+ (NSArray *) cachedObjectsFromPath:(NSString *)path withAuthorization:(NSString *)authorization andCallback:(void (^)(id))callback;

+ (void) setUrlBase:(NSString *)url;
+ (NSString *) authorizationWithUsername:(NSString *)username andPassword:(NSString *)password;

+ (id) postData:(NSDictionary *)data toPath:(NSString *)path;
+ (id) postData:(NSDictionary *)data toPath:(NSString *)path withAuthorization:(NSString *)authorization;
+ (id) getDataFromPath:(NSString *)path;
+ (id) getDataFromPath:(NSString *)path withAuthorization:(NSString *)authorization;


/*
 Thoughts:
 
 Calling setUrlBase: should be required.
 
 The "Path" will be used as a means of looking up an object in cache.
 
 By default GETs are cached indefiniately. - Nothing else.
 --> Options: Disabled caching, or set max age.
 
 */


@end
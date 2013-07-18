//
//  MBase.h
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
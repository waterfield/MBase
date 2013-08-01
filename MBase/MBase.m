//
//  MBase.m
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

#import "MBase.h"
#import <Foundation/NSObjCRuntime.h>
#import <objc/runtime.h>
#import "SBJson.h"
#import "NSString+base64.h"
#import "NSObject+Properties.h"
#import "MBaseOffline.h"

static NSURL *urlBase;

@implementation MBase

- (id) initWithDictionary:(NSDictionary *)dictionary{    
    NSArray *properties = [self propertyNames];
    for(int i = 0; i != [properties count]; i++){
        NSString *propertyName = [properties objectAtIndex:i];
        id value = [dictionary objectForKey:[self translatePropertyName:propertyName]];
        if(value){
            @try{
                id convertedValue = [self convertObject:value toTypeForProperty:propertyName];
                if (convertedValue) {
                    [self setValue:convertedValue forKey:propertyName];
                }
            } @catch(NSException *e){
                NSLog(@"Exception: %@", e);
            }
        }else{
            NSString *foreignKey = [self foreignKeyForProperty:propertyName];
            if(foreignKey){
                [NSException raise:@"Unimplemented feature!" format:@"foreign key for %@ not handled", propertyName];
            }
        }
    }
    
    return self;
}

- (id) initWithContentFromPath:(NSString *)path{
    return [self initWithContentFromPath:path withAuthorization:nil];
}

- (id) initWithContentFromPath:(NSString *)path withAuthorization:(NSString *)authorization{
    NSDictionary *rawData = [[self class] getDataFromPath:path withAuthorization:authorization];
    id instance = nil;
    if(rawData){
        instance = [self initWithDictionary:rawData];
    }
    return instance;
}

- (id) inspect{
    SBJsonWriter *helper = [SBJsonWriter new];
    return [helper stringWithObject:self];
}

- (NSDictionary *) toDictionary{
    NSMutableDictionary *result = [NSMutableDictionary new];
    
    NSArray *properties = [self propertyNames];
    for(int i = 0; i != [properties count]; i++){
        NSString *propertyName = [properties objectAtIndex:i];
        
        NSString *key = [self translatePropertyName:propertyName];
        id value = [self valueForKey:propertyName];
        if(value)
            [result setObject:value forKey:key];
    }

    
    return result;
}

+ (NSArray *) objectsFromPath:(NSString *)path{
    return [self objectsFromPath:path withAuthorization:nil];
}

+ (NSArray *) objectsFromPath:(NSString *)path withAuthorization:(NSString *)authorization{
    NSArray *rawResults = [self getDataFromPath:path withAuthorization:authorization];
    NSMutableArray *results = [NSMutableArray new];
    
    for (int i = 0; i < rawResults.count; i++) {
        id instance = [[self alloc] initWithDictionary: [rawResults objectAtIndex: i]];
        [results addObject:instance];
    }
    
    return results;
}

+ (void) setUrlBase:(NSString *)url{
    urlBase = [NSURL URLWithString:url];
}

+ (void) enableOfflineSupport{
    [[MBaseOffline instance] setApiHost:[urlBase host]];
}

+ (NSString *) authorizationWithUsername:(NSString *)username andPassword:(NSString *)password{
    NSString *authorization = [NSString stringWithFormat:@"%@:%@", username, password];
    return [authorization base64Encode];
}

+ (id) postData:(NSDictionary *)data toPath:(NSString *)path{
    return [self postData:data toPath:path withAuthorization:nil];
}

+ (id) postData:(NSDictionary *)data toPath:(NSString *)path withAuthorization:(NSString *)authorization{
    if(![[MBaseOffline instance] apiReachable]){
        [[MBaseOffline instance] cachePostData:data toPath:path withAuthorization:authorization];
        
        return nil; //??
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"POST"];
    if(data){
        NSString *json = [data JSONRepresentation];
        NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
        
        [request setHTTPBody:data];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"%d", [data length]] forHTTPHeaderField:@"Content-Length"];
    }
    if(authorization){
        [request addValue:authorization forHTTPHeaderField:@"Authorization"];
    }
    if(urlBase){
        [request setURL:[NSURL URLWithString:path relativeToURL:urlBase]];
    }else{
        [request setURL:[NSURL URLWithString:path]];
    }
    
    NSError *error = [[NSError alloc] init];
    NSHTTPURLResponse *responseCode = nil;
    
    NSData *oResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:&error];
    NSString *stringData = [[NSString alloc] initWithData:oResponseData encoding:NSUTF8StringEncoding];
    
    if([responseCode statusCode] < 200 || [responseCode statusCode] >= 300){
        NSLog(@"status code -> %i", [responseCode statusCode]);
        NSLog(@"response data -> %@", [[NSString alloc] initWithData:oResponseData encoding:NSUTF8StringEncoding]);
        return nil;
    }
    
    SBJsonParser *parser = [[SBJsonParser alloc] init];
    return [parser objectWithString:stringData];
}

+ (id) getDataFromPath:(NSString *)path{
    return [self getDataFromPath:path withAuthorization:nil];
}

+ (id) getDataFromPath:(NSString *)path withAuthorization:(NSString *)authorization{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    if(authorization){
        [request addValue:authorization forHTTPHeaderField:@"Authorization"];
    }
    if(urlBase){
        [request setURL:[NSURL URLWithString:path relativeToURL:urlBase]];
    }else{
        [request setURL:[NSURL URLWithString:path]];
    }
    
    NSError *error = [[NSError alloc] init];
    NSHTTPURLResponse *responseCode = nil;
    
    NSData *oResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:&error];
    
    if([responseCode statusCode] != 200){
        NSLog(@"status code -> %i", [responseCode statusCode]);
        NSLog(@"response data -> %@", [[NSString alloc] initWithData:oResponseData encoding:NSUTF8StringEncoding]);
        return nil;
    }
    
    NSString *stringData = [[NSString alloc] initWithData:oResponseData encoding:NSUTF8StringEncoding];
    
    SBJsonParser *parser = [[SBJsonParser alloc] init];
    return [parser objectWithString:stringData];
}

//---- cache ----
+ (NSArray *) cachedObjectsFromPath:(NSString *)path withCallback:(void (^)(id))callback{
    
    return [self cachedObjectsFromPath:path withAuthorization:nil andCallback:callback];
}

+ (NSArray *) cachedObjectsFromPath:(NSString *)path withAuthorization:(NSString *)authorization andCallback:(void (^)(id))callback{
    
    NSString *cacheKey = [path stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    NSArray *cachedObjects = [self getObjectsFromFile:cacheKey];
    
    if (cachedObjects == nil) {
        //NSLog(@"cachedObjectsFromPath %@ == nil", path);
        // load new data and set initial cache
        NSArray *rawData = [self getDataFromPath:path withAuthorization:authorization];
        NSMutableArray *results = [NSMutableArray new];
        for (int i = 0; i < rawData.count; i++) {
            id instance = [[self alloc] initWithDictionary:[rawData objectAtIndex:i]];
            [results addObject:instance];
        }
        
        NSArray *processedResults = [NSArray arrayWithArray:results];
        
        [self storeObjects:processedResults toFile:cacheKey];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            callback(processedResults);
        });
        
        return processedResults;
    } else {
        //NSLog(@"cachedObjectsFromPath %@: %@", path, cachedObjects);
        // return cached object
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // load new data and set initial cache
            NSArray *rawData = [self getDataFromPath:path withAuthorization:authorization];
            NSMutableArray *results = [NSMutableArray new];
            for (int i = 0; i < rawData.count; i++) {
                id instance = [[self alloc] initWithDictionary:[rawData objectAtIndex:i]];
                [results addObject:instance];
            }
            
            NSArray *processedResults = [NSArray arrayWithArray:results];
            
            [self storeObjects:processedResults toFile:cacheKey];
            
            callback(processedResults);
        });
        
        return cachedObjects;
    }
}

+ (void) storeObjects:(NSArray *)objects toFile:(NSString *)filename {
    // NSLog(@"storeData: %@ toFile: %@", data, filename);
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, true);
    NSString *libraryDirectory = [paths objectAtIndex:0];
    NSString *file = [libraryDirectory stringByAppendingString:[NSString stringWithFormat:@"/%@", filename]];
    BOOL cacheFileCreated = [NSKeyedArchiver archiveRootObject:objects toFile:file];
    if (cacheFileCreated) {
        // prevent created file from being backed up to iCloud; requires iOS 5.1+
        NSURL *fileUrl = [NSURL fileURLWithPath:file];
        [fileUrl setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
    } else {
        // could not create file; next call requesting cached data will have to make live request
        NSLog(@"could not create cache file");
    }
}

+ (NSArray *) getObjectsFromFile:(NSString *)filename{
    //NSLog(@"getDataFromFile: %@", filename);
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = [paths objectAtIndex:0];
    NSString *filePath = [libraryDirectory stringByAppendingString:[NSString stringWithFormat:@"/%@", filename]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSArray *objects = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        return objects;
    } else {
        return nil;
    }
}

//---- NSCoding ----
- (void)encodeWithCoder:(NSCoder *)coder {
    for (NSString *propertyName in self.propertyNames) {
        
        if ([self propertyIsBoolean:propertyName]) {
            // if the property is a bool, encodeBool
            bool boolValue = [self performSelector:[self getterForPropertyNamed:propertyName]];
            NSNumber *boolNumber = [NSNumber numberWithBool:boolValue];
            [coder encodeObject:boolNumber forKey:propertyName];
            // NSLog(@"encodeObject: boolNumber: %@", propertyName);
        } else {
            // otherwise, get object unless it is an image
            if (![self propertyIsImage:propertyName]) {
                id object = [self valueForKey:propertyName];
                if (!(object == nil)) {
                    [coder encodeObject:object forKey:propertyName];
                }
            }
        }
    }
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    for (NSString *propertyName in self.propertyNames) {
        
        if ([coder containsValueForKey:propertyName]) {
            // if a value was cached, load it
            if ([self propertyIsBoolean:propertyName]) {
                // if the property is a bool, decode NSNumber numberWithBool
                NSNumber *boolNumber = [coder decodeObjectForKey:propertyName];
                [self setValue:boolNumber forKey:propertyName];
                // NSLog(@"decodeObject: boolNumber: %@", propertyName);
            } else {
                // otherwise, get object
                id object = [coder decodeObjectForKey:propertyName];
                if (!(object == nil)) {
                    [self setValue:object forKey:propertyName];
                }
            }
        }
    }
    return self;
}

//---- private ----
- (NSString *) translatePropertyName:(NSString *)propertyName{
    NSString *alias = [self aliasForProperty:propertyName];
    return alias ? alias : [self camelToSnake:propertyName];
}

- (NSString *) camelToSnake:(NSString *)camel{
    //responsible for translating camel case to snake case.
    //generally this is not called directly... only really intended for use by
    //- (NSString *) translatePropertyName:(NSString*)propertyName
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([A-Z])"
                                                                           options:NSRegularExpressionAnchorsMatchLines
                                                                             error:&error];
    
    NSString *snake = [regex stringByReplacingMatchesInString:camel
                                                      options:0
                                                        range:NSMakeRange(0, [camel length])
                                                 withTemplate:@"_$1"];
    return [snake lowercaseString];
}

- (NSString *) aliasForProperty:(NSString *)propertyName{
    //responsible for looking up method aliases.
    //generally this is not called directly... only really intended for use by
    //- (NSString *) translatePropertyName:(NSString*)propertyName
    NSDictionary *mapping = [self respondsToSelector:@selector(msbaseAliases)] == false ? nil
    : [self performSelector:@selector(msbaseAliases)];
    
    if(mapping == nil | [mapping isKindOfClass:[NSDictionary class]] == false)
        return nil;
    
    return [mapping objectForKey:propertyName];
}

- (NSString *) foreignKeyForProperty:(NSString *)propertyName{
    if (! [self respondsToSelector:@selector(mbaseRelationships)] ) {
        return nil;
    }
    
    NSArray *foreignKeys = [self performSelector:@selector(mbaseRelationships)];
    
    for (int i = 0; i < [foreignKeys count]; i++) {
        NSDictionary *foreignKey = [foreignKeys objectAtIndex:i];
        //NSLog(@"foreignKeyForProperty: isEqualToString");
        if ([[foreignKey objectForKey: _belongsTo] isEqualToString:propertyName]) {
            return [foreignKey objectForKey: _foreignKey];
        }
        //NSLog(@"foreignKeyForProperty: /isEqualToString");
    }
    
    return nil;
}

- (NSArray *)objectsForHasManyRelationship:(NSString *)propertyName withArray:(NSArray *)relationArray {
    if (! [self respondsToSelector:@selector(mbaseRelationships)] ) {
        return nil;
    }
    
    NSArray *foreignKeys = [self performSelector:@selector(mbaseRelationships)];
    
    
    NSMutableArray *objects = [NSMutableArray new];
    
    for (int i = 0; i < [foreignKeys count]; i++) {
        NSDictionary *foreignKey = [foreignKeys objectAtIndex:i];
        //NSLog(@"foreignKey objectForKey hasMany isEqualToString");
        if ([[foreignKey objectForKey:_hasMany] isEqualToString:propertyName]) {
            //NSLog(@"foreignKey objectForKey hasMany /isEqualToString");
            NSString *hasManyName = [foreignKey objectForKey:_hasMany];
            // get class name based on relation name
            NSString *className = [hasManyName substringToIndex:[hasManyName length] - 1];
            className = [className stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[className substringToIndex:1] uppercaseString]];
            Class class = NSClassFromString(className);
            if (![class isSubclassOfClass:[MBase class]]) {
                // the class is not valid
                return nil;
            }
            for (NSDictionary *objectDictionary in relationArray) {
                id object = [[class alloc] initWithDictionary:objectDictionary];
                [objects addObject:object];
            }
            return objects; // exit loop after reaching correct foreignKey
        }
    }
    
    return objects;
}

/* See documentation at https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html%23//apple_ref/doc/uid/TP40008048-CH100-SW1 */
- (id) convertObject:(id)obj toTypeForProperty:(NSString *) propertyName{
    const char *buffer = [self typeOfPropertyNamed:propertyName];
    
    NSString *targetClass = [[NSString alloc] initWithCString:buffer encoding:NSASCIIStringEncoding];
    // NSString *originalTargetClass = [NSString stringWithFormat:@"%@", targetClass];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"T@\"([^\"]+)\"" options:NSRegularExpressionAnchorsMatchLines error:nil];
    targetClass = [regex stringByReplacingMatchesInString:targetClass options:0 range:NSMakeRange(0, [targetClass length]) withTemplate:@"$1"];
    
    Class class = NSClassFromString(targetClass);
    
    //if the target type is NSArray, deal with _hasMany relationship
    if([targetClass isEqualToString:@"NSArray"]) {
        return [self objectsForHasManyRelationship:propertyName withArray:obj];
    }
    //NSLog(@"targetClass /isEqualToString: NSArray");
    
    //if the target type is NSNumber, and the source is NSString...
    if([targetClass isEqualToString:@"NSNumber"] && [obj isKindOfClass:[NSString class]]){
        NSNumberFormatter * formatter = [NSNumberFormatter new];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        return [formatter numberFromString:obj];
    }
    //NSLog(@"targetClass /isEqualToString NSNumber");
    //if target type is boolean, and the source is NSString...
    if([targetClass isEqualToString:@"TB"] && [obj isKindOfClass:[NSString class]]){
        bool value = [obj boolValue];
        return [NSNumber numberWithBool:value];
    }
    //NSLog(@"targetClass /isEqualToString TB isKindOfClass NSString: %@", targetClass);
    //if target type is boolean, and the source is NSNumber...
    if([targetClass isEqualToString:@"TB"] && [obj isKindOfClass:[NSNumber class]]){
        //NSLog(@"target boolean: %@, source NSNumber: %@ -> %@", propertyName, targetClass, obj);
        bool value = [obj boolValue];
        return [NSNumber numberWithBool:value];
    }
    //NSLog(@"targetClass /isEqualToString TB isKindOfClass NSNumber");
    
    //if the target type is NSDate, and the source is NSString...
    if([targetClass isEqualToString:@"NSDate"] && [obj isKindOfClass:[NSString class]]) {
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        NSDate *result = [dateFormatter dateFromString:obj];
        if(!result){
            [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZ"];
            result = [dateFormatter dateFromString:obj];
        }
        if(!result){
            [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
            result = [dateFormatter dateFromString:obj];
        }
        if(!result){
            //2013-07-12T09:55:26.523
            [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
            result = [dateFormatter dateFromString:obj];
        }
        return result;
    }
    //NSLog(@"targetClass /isEqualToString NSDate");
    
    //if the target class is a child of MBase, and the source is NSDictionary...
    if([class isSubclassOfClass:[MBase class]] &&[obj isKindOfClass:[NSDictionary class]]){
        return [[class alloc] initWithDictionary:obj];
    }
    
    //if they are the same type... well, this is easy :-)
    if([obj isKindOfClass:NSClassFromString(targetClass)] ){
        return obj;
    }
    
    // last chance... if the target class is NSString, use the stringValue
    if([targetClass isEqualToString:@"NSString"] && [obj respondsToSelector:@selector(stringValue)]){
        return [obj stringValue];
    }
    
    //else...
    /*
     if(obj != nil){
     //NSLog(@"No conversion found for %@ (%@/%@) -> %@", propertyName, targetClass, originalTargetClass, obj);
     }
     */
    return nil; //no conversion found
}

- (bool)propertyIsBoolean:(NSString *)propertyName {
    const char *buffer = [self typeOfPropertyNamed:propertyName];
    
    NSString *targetClass = [[NSString alloc] initWithCString:buffer encoding:NSASCIIStringEncoding];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"T@\"([^\"]+)\"" options:NSRegularExpressionAnchorsMatchLines error:nil];
    targetClass = [regex stringByReplacingMatchesInString:targetClass options:0 range:NSMakeRange(0, [targetClass length]) withTemplate:@"$1"];
    return [targetClass isEqualToString:@"TB"];
}

- (bool)propertyIsImage:(NSString *)propertyName {
    const char *buffer = [self typeOfPropertyNamed:propertyName];
    
    NSString *targetClass = [[NSString alloc] initWithCString:buffer encoding:NSASCIIStringEncoding];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"T@\"([^\"]+)\"" options:NSRegularExpressionAnchorsMatchLines error:nil];
    targetClass = [regex stringByReplacingMatchesInString:targetClass options:0 range:NSMakeRange(0, [targetClass length]) withTemplate:@"$1"];
    return [targetClass isEqualToString:@"UIImage"];
}

@end
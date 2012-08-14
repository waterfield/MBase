//
//  MBase.m
//  MBase
//
//  Created by Jason Whitehorn on 7/26/12.
//  Copyright (c) 2012 Waterfield Technologies. All rights reserved.
//

#import "MBase.h"
#import <Foundation/NSObjCRuntime.h>
#import <objc/runtime.h>
#import "SBJson.h"
#import "NSString+base64.h"
#import "NSObject+Properties.h"

static NSURL *urlBase;

@implementation MBase

- (id) initWithDictionary:(NSDictionary *)dictionary{
    NSArray *properties = [self propertyNames];
    for(int i = 0; i != [properties count]; i++){
        NSString *propertyName = [properties objectAtIndex:i];
        id value = [dictionary objectForKey:[self translatePropertyName:propertyName]];
        if(value){
            id convertedValue = [self convertObject:value toTypeForProperty:propertyName];
            [self setValue:convertedValue forKey:propertyName];
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

+ (NSString *) authorizationWithUsername:(NSString *)username andPassword:(NSString *)password{
    NSString *authorization = [NSString stringWithFormat:@"%@:%@", username, password];
    return [authorization base64Encode];
}

+ (id) postData:(NSDictionary *)data toPath:(NSString *)path{
    return [self postData:data toPath:path withAuthorization:nil];
}

+ (id) postData:(NSDictionary *)data toPath:(NSString *)path withAuthorization:(NSString *)authorization{
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
        if ([[foreignKey objectForKey: _belongsTo] isEqualToString:propertyName]) {
            return [foreignKey objectForKey: _foreignKey];
        }
    }
    
    return nil;
}

- (id) convertObject:(id)obj toTypeForProperty:(NSString *) propertyName{
    NSString *targetClass = [NSString stringWithUTF8String:[self typeOfPropertyNamed:propertyName]];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"T@\"([^\"]+)\"" options:NSRegularExpressionAnchorsMatchLines error:nil];
   targetClass = [regex stringByReplacingMatchesInString:targetClass options:0 range:NSMakeRange(0, [targetClass length]) withTemplate:@"$1"];
    
    Class class = NSClassFromString(targetClass);
        
    //if the target type is NSNumber, and the source is NSString...
    if([targetClass isEqualToString:@"NSNumber"] && [obj isKindOfClass:[NSString class]]){
        NSNumberFormatter * formatter = [NSNumberFormatter new];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        return [formatter numberFromString:obj];
    }
    //if target type is boolean, and the source is NSString...
    if([targetClass isEqualToString:@"TB"] && [obj isKindOfClass:[NSString class]]){
        bool value = [obj boolValue];
        return [NSNumber numberWithBool:value];
    }
    //if target type is boolean, and the source is NSNumber...
    if([targetClass isEqualToString:@"TB"] && [obj isKindOfClass:[NSNumber class]]){
        bool value = [obj boolValue];
        return [NSNumber numberWithBool:value];
    }
    
    if([class isSubclassOfClass:[MBase class]] &&[obj isKindOfClass:[NSDictionary class]]){
        return [[class alloc] initWithDictionary:obj];
    }
    
    //if they are the same type... well, this is easy :-)
    if([obj isKindOfClass:NSClassFromString(targetClass)] ){
        return obj;
    }
    //last chance...
    if([targetClass isEqualToString:@"NSString"] && [obj respondsToSelector:@selector(stringValue)]){
        return [obj stringValue];
    }
    //else...
    return nil; //no conversion found
}


@end
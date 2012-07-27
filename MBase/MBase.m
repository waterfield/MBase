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

@implementation MBase

- (id) initWithDictionary:(NSDictionary *)dictionary{
    NSArray *properties = [self propertyNames];
    for(int i = 0; i != [properties count]; i++){
        NSString *propertyName = [properties objectAtIndex:i];
        id value = [dictionary objectForKey:[self camelToSnake:propertyName]];
        if(value){
            id convertedValue = [self convertObject:value toTypeForProperty:propertyName];
            [self setValue:convertedValue forKey:propertyName];
        }
    }
    
    return self;
}

+ (NSString *) authorizationWithUsername:(NSString *)username andPassword:(NSString *)password{
    NSString *authorization = [NSString stringWithFormat:@"%@:%@", username, password];
    return [authorization base64Encode];
}

+ (id) postData:(NSDictionary *)data toUrl:(NSString *)url{
    return [self postData:data toUrl:url withAuthorization:nil];
}

+ (id) postData:(NSDictionary *)data toUrl:(NSString *)url withAuthorization:(NSString *)authorization{
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
    [request setURL:[NSURL URLWithString:url]];
    
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

+ (id) getDataFromUrl:(NSString *)url{
    return [self getDataFromUrl:url withAuthorization:nil];
}

+ (id) getDataFromUrl:(NSString *)url withAuthorization:(NSString *)authorization{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    if(authorization){
        [request addValue:authorization forHTTPHeaderField:@"Authorization"];
    }
    [request setURL:[NSURL URLWithString:url]];
    
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
- (NSString *) camelToSnake:(NSString *)camel{
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

- (id) convertObject:(id)obj toTypeForProperty:(NSString *) propertyName{
    NSString *className = [NSString stringWithUTF8String:[self typeOfPropertyNamed:propertyName]];
    NSString *targetClassName = [NSString stringWithUTF8String:class_getName([obj class])];
    
    if([className isEqualToString:targetClassName]){
        return obj;
    }
    if([className isEqualToString:@"NSString"] && [targetClassName isEqualToString:@"NSNumber"]){
        NSNumberFormatter * formatter = [NSNumberFormatter new];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        return [formatter numberFromString:obj];
    }
    //last chance...
    if([targetClassName isEqualToString:@"NSString"] && [obj hasPropertyNamed:@"stringValue"]){
        return [obj stringValue];
    }
    //else...
    return nil; //no conversion found
}

@end
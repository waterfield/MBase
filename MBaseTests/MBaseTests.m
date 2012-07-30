//
//  MBaseTests.m
//  MBaseTests
//
//  Created by Jason Whitehorn on 7/26/12.
//  Copyright (c) 2012 Waterfield Technologies. All rights reserved.
//

#import "MBaseTests.h"
#import "TestModel.h"

@interface MBase (Private)

- (NSString *) camelToSnake:(NSString *)camel;
- (id) convertObject:(id)obj toTypeForProperty:(NSString *) propertyName;

@end

@implementation MBaseTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void) testConvertNSStringToNSNumber{
    TestModel *helper = [TestModel new];
    NSString *string = [NSString stringWithFormat:@"%@%@", @"12", @"3"];
    id output = [helper convertObject:string toTypeForProperty:@"aNumber"];
    
    STAssertTrue([output isKindOfClass:[NSNumber class]], @"Should be of type NSNumber, instead it was %@", [output class]);
}

- (void) testConvertConstantStringToNSNumber{
    TestModel *helper = [TestModel new];
    NSString *string = @"123";
    id output = [helper convertObject:string toTypeForProperty:@"aNumber"];
    
    STAssertTrue([output isKindOfClass:[NSNumber class]], @"Should be of type NSNumber, instead it was %@", [output class]);
}

- (void) testConvertNSStringToNSString{
    TestModel *helper = [TestModel new];
    NSString *string = [NSString stringWithFormat:@"%@%@", @"12", @"3"];
    id output = [helper convertObject:string toTypeForProperty:@"aString"];
    
    STAssertTrue([output isKindOfClass:[NSString class]], @"Should be of type NSString, instead it was %@", [output class]);
}

@end

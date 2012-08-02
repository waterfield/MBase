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
- (NSString *) translatePropertyName:(NSString *)propertyName;

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

- (void) testConvertNSNumberToNSNumber{
    TestModel *helper = [TestModel new];
    NSNumber *num = [[NSNumber alloc] initWithInt:123];
    id output = [helper convertObject:num toTypeForProperty:@"aNumber"];
    
    STAssertTrue([[output aNumber] isEqualToNumber:num], @"aNumber should have been 123, but instead was %@", [output aNumber]);
}

- (void) testConvertNSStringToTestModel{
    TestModel *helper = [TestModel new];
    NSString *string = [NSString stringWithFormat:@"%@%@", @"12", @"3"];
    id output = [helper convertObject:string toTypeForProperty:@"aTest"];
    
    STAssertNil(output, @"Expected conversion to produce nil, actual output %@", output);
}

- (void) testAliasLookup {
    TestModel *helper = [TestModel new];
    NSString *alias = [helper translatePropertyName:@"testId"];
    
    STAssertTrue([alias isEqualToString:@"id"], @"alias should be equal to 'id', but instead was %@", alias);
}

- (void) testRespectsAliases{
    TestModel *output = [[TestModel alloc] initWithDictionary:@{ @"id" : [NSNumber numberWithInt:123] }];
    STAssertEquals([output testId], 123, @"testId should have equaled 123, but instead was %i", [output testId]);
}

@end

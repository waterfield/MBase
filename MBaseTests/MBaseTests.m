//
//  MBaseTests.m
//  MBaseTests
//
//  Created by Jason Whitehorn on 7/26/12.
//  Copyright (c) 2012-2013 Waterfield Technologies. All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "MBaseTests.h"
#import "TestModel.h"
#import "AnotherTestModel.h"
#import "SBJson.h"
//#import "Transaction.h"

@interface MBase (Private)

- (NSString *) camelToSnake:(NSString *)camel;
- (id) convertObject:(id)obj toTypeForProperty:(NSString *) propertyName;
- (NSString *) translatePropertyName:(NSString *)propertyName;
- (NSString *) foreignKeyForProperty:(NSString *)propertyName;

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
    
    STAssertTrue([output isEqualToNumber:num], @"aNumber should have been 123, but instead was %@", [output aNumber]);
}

- (void) testConvertNSStringToTestModel{
    TestModel *helper = [TestModel new];
    NSString *string = [NSString stringWithFormat:@"%@%@", @"12", @"3"];
    id output = [helper convertObject:string toTypeForProperty:@"aTest"];
    
    STAssertNil(output, @"Expected conversion to produce nil, actual output %@", output);
}

- (void) testConvertNSStringToBool{
    TestModel *helper = [TestModel new];
    NSString *string = @"1";
    id output = [helper convertObject:string toTypeForProperty:@"aBool"];
    
    STAssertTrue([output isKindOfClass:[NSNumber class]], @"Should be of type NSNumber, instead it was %@", [output class]);
    STAssertTrue([output boolValue], @"Boolean value of output should have been true, but instead was false");
}

- (void) testAliasLookup {
    TestModel *helper = [TestModel new];
    NSString *alias = [helper translatePropertyName:@"testId"];
    
    STAssertTrue([alias isEqualToString:@"id"], @"alias should be equal to 'id', but instead was %@", alias);
}

- (void) testRespectsAliases{
    NSNumber *num = [NSNumber numberWithInt:123];
    TestModel *output = [[TestModel alloc] initWithDictionary:@{ @"id" : num }];
    STAssertTrue([[output testId] isEqualToNumber:num], @"testId should have equaled 123, but instead was %@", [output testId]);
}

- (void) testBoolBoxingOne{
    TestModel *output = [[TestModel alloc] initWithDictionary:@{ @"a_bool" : @"1" }];
    
    STAssertTrue(output.aBool, @"aBool should have been true, it was false");
}

- (void) testBoolBoxingZero{
    TestModel *output = [[TestModel alloc] initWithDictionary:@{ @"a_bool" : @"0" }];
    
    STAssertFalse(output.aBool, @"aBool should have been false, it was true");
}

- (void) testBoolBoxingTrue{
    TestModel *output = [[TestModel alloc] initWithDictionary:@{ @"a_bool" : @"true" }];
    
    STAssertTrue(output.aBool, @"aBool should have been true, it was false");
}

- (void) testBoolBoxingFalse{
    TestModel *output = [[TestModel alloc] initWithDictionary:@{ @"a_bool" : @"false" }];
    
    STAssertFalse(output.aBool, @"aBool should have been false, it was true");
}

- (void) testBoolBoxingOneNumber{
    TestModel *output = [[TestModel alloc] initWithDictionary:@{ @"a_bool" : [NSNumber numberWithInt:1] }];
    
    STAssertTrue(output.aBool, @"aBool should have been true, it was false");
}

- (void) testBoolBoxingZeroNumber{
    TestModel *output = [[TestModel alloc] initWithDictionary:@{ @"a_bool" : [NSNumber numberWithInt:0] }];
    
    STAssertFalse(output.aBool, @"aBool should have been false, it was true");
}

- (void) testAnotherModelHasRelationships{
    AnotherTestModel *helper = [AnotherTestModel new];
    
    STAssertTrue([helper respondsToSelector:@selector(mbaseRelationships)], @"does not responds to mbaseRelationships");
}

- (void) testTestModelHasRelationships{
    TestModel *helper = [TestModel new];
    
    STAssertFalse([helper respondsToSelector:@selector(mbaseRelationships)], @"responds to mbaseRelationships");
}

- (void) testInvalidRelationship {
    TestModel *model = [TestModel new];
    
    STAssertNil([model foreignKeyForProperty: @"invalidProperty"], @"does not return nil for invalid relationship");
}

- (void) testValidRelationship {
    AnotherTestModel *model = [AnotherTestModel new];
    NSString *foreignKey =[model foreignKeyForProperty: @"testModel"];
    
    STAssertTrue([foreignKey isEqualToString:@"testModelId"], @"should have returned 'testModelId', instead returned %@", foreignKey);
}

- (void) testEmbeddedObject {
    NSDictionary *testData = @{ @"a_number": @123, @"a_string": @"aString", @"an_embedded_model": @{@"a_string": @"anEmbeddedString", @"a_number": @456}};
    
    TestModel *testModel = [[TestModel alloc] initWithDictionary:testData];
    
    STAssertTrue([[testModel aNumber] isEqualToNumber: @123], @"");
    STAssertTrue([[testModel aString] isEqualToString: @"aString"], @"");
    
    EmbeddedTestModel *embeddedModel = [testModel anEmbeddedModel];
    STAssertNotNil(embeddedModel, @"embedded model is nil");
    
    STAssertTrue([[embeddedModel aNumber] isEqualToNumber: @456], @"");
    STAssertTrue([[embeddedModel aString] isEqualToString: @"anEmbeddedString"], @"");

    //make assertion
}

- (void) testEmbeddedObjectWithJson {
    // check for embedded object
    
    NSString *testJson = @"{\"a_number\":123,\"a_string\":\"aString\",\"an_embedded_model\":{\"a_string\":\"anEmbeddedString\",\"a_number\":456}}";
    
    SBJsonParser *parser = [[SBJsonParser alloc] init];
    NSDictionary *testData = [parser objectWithString:testJson];

    
    TestModel *testModel = [[TestModel alloc] initWithDictionary:testData];
    
    STAssertTrue([[testModel aNumber] isEqualToNumber: @123], @"should be 123, but was %@", [testModel aNumber]);
    STAssertTrue([[testModel aString] isEqualToString: @"aString"], @"should be 'aString', but was %@", [testModel aString]);
    
    EmbeddedTestModel *embeddedModel = [testModel anEmbeddedModel];
    STAssertNotNil(embeddedModel, @"embedded model is nil");
    
    STAssertTrue([[embeddedModel aNumber] isEqualToNumber: @456], @"");
    STAssertTrue([[embeddedModel aString] isEqualToString: @"anEmbeddedString"], @"");
    
    //make assertion
}

- (void) testEmbeddedObjectWithJsonTwo {
    // check for embedded object
    
    NSString *testJson = @"{\"a_number\":123,\"a_string\":\"aString\",\"an_embedded_model\":\"{\\\"a_string\\\":\\\"anEmbeddedString\\\",\\\"a_number\\\":456}\"}";
    
    SBJsonParser *parser = [[SBJsonParser alloc] init];
    NSDictionary *testData = [parser objectWithString:testJson];
    
    
    TestModel *testModel = [[TestModel alloc] initWithDictionary:testData];
    
    STAssertTrue([[testModel aNumber] isEqualToNumber: @123], @"should be 123, but was %@", [testModel aNumber]);
    STAssertTrue([[testModel aString] isEqualToString: @"aString"], @"should be 'aString', but was %@", [testModel aString]);
    
    EmbeddedTestModel *embeddedModel = [testModel anEmbeddedModel];
    
    //assert that we cannot handle a object (incorrectly) encoded as a string
    STAssertNil(embeddedModel, @"embedded model should be nil");
}

@end

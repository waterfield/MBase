//
//  TestModel.h
//  MBase
//
//  Created by Jason Whitehorn on 7/27/12.
//  Copyright (c) 2012 Waterfield Technologies. All rights reserved.
//

#import "MBase.h"
#import "EmbeddedTestModel.h"

@interface TestModel : MBase

@property (strong) NSNumber *testId;
@property (strong) NSNumber *aNumber;
@property (strong) NSString *aString;
@property (strong) TestModel *aTest;
@property bool aBool;
@property (strong) EmbeddedTestModel *anEmbeddedModel;

@end

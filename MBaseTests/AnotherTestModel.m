//
//  AnotherTestModel.m
//  MBase
//
//  Created by Jason Whitehorn on 8/13/12.
//  Copyright (c) 2012 Waterfield Technologies. All rights reserved.
//

#import "AnotherTestModel.h"

@implementation AnotherTestModel

with_relationships((@[
                    @{ _belongsTo : @"testModel", _foreignKey : @"testModelId" }
                    ]))

@end

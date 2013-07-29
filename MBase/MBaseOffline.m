//
//  MBaseOffline
//  MBase
//
//  Created by Jason Whitehorn on 7/29/13.
//  Copyright (c) 2012-2013 Waterfield Technologies. All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#import "MBaseOffline.h"
#import "Reachability.h"

MBaseOffline * __MBASEOFFLINE_INSTANCE;

@implementation MBaseOffline
@synthesize reachability;

+ (MBaseOffline *) instance{
    @synchronized(self){
        if(!__MBASEOFFLINE_INSTANCE)
            __MBASEOFFLINE_INSTANCE = [MBaseOffline new];
        return __MBASEOFFLINE_INSTANCE;
    }
}

- (void) setApiHost:(NSString *)hostname{
    reachability = [Reachability reachabilityWithHostname:hostname];
    __weak MBaseOffline *this = self;
    reachability.reachableBlock = ^(Reachability *reach){
        [this flushPendingUpdates];
    };
    [reachability startNotifier];
}

- (bool) apiReachable{
    return reachability && [reachability isReachable];
}

- (bool) offlineSupport{
    return reachability != nil;
}

- (void) registerClass:(Class)klass{
    //TODO
}

- (void) flushPendingUpdates{
    //TODO
}

@end

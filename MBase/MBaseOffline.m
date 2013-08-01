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
#import "OfflineData.h"
#import "SBJson.h"

MBaseOffline * __MBASEOFFLINE_INSTANCE;

@interface MBaseOffline()
@property (strong) NSString *filename;
@property (strong) NSMutableArray *queue;

- (void) load;
- (void) save;
- (OfflineData *) dequeue;
@end

@implementation MBaseOffline
@synthesize reachability, filename, queue;

+ (MBaseOffline *) instance{
    @synchronized(self){
        if(!__MBASEOFFLINE_INSTANCE)
            __MBASEOFFLINE_INSTANCE = [MBaseOffline new];
        return __MBASEOFFLINE_INSTANCE;
    }
}

+ (void) setInstance:(MBaseOffline *)instance{
    __MBASEOFFLINE_INSTANCE = instance;
}

- (id) init{
    self = [super init];
    if(self){
        self.filename = @"mbase_queue.json";
        [self load];
    }
    return self;
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

- (void) flushPendingUpdates{
    if(![reachability isReachable]){
        return;
    }
    @synchronized(self){
        OfflineData *item = [self dequeue];
        [MBase postData:item.data toPath:item.path withAuthorization:item.authorization]; //if this fails, MBase will requeue
    }
    if([queue count] > 0){
        [self performSelector:@selector(flushPendingUpdates) withObject:nil afterDelay:1];
    }
}

- (void) cachePostData:(NSDictionary *)data toPath:(NSString *)path withAuthorization:authorization {
    @synchronized(self){
        [queue addObject:@{@"data" : data, @"auth" : authorization, @"path" : path}];
        [self save];
    }
}

//--- "private"

- (OfflineData *) dequeue{
    OfflineData *result = nil;
    @synchronized(self){
        if([queue count] > 0){
            NSDictionary *rawData = [queue objectAtIndex:0];
            result = [OfflineData new];
            result.data = [rawData objectForKey:@"data"];
            result.path = [rawData objectForKey:@"path"];
            result.authorization = [rawData objectForKey:@"auth"];
            
            [queue removeObjectAtIndex:0];
            [self save];
        }
    }
    return result;
}

- (void) load{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = [paths objectAtIndex:0];
    NSString *file = [libraryDirectory stringByAppendingString:filename];
    
    NSData *rawData = [NSData dataWithContentsOfFile:file];
    if(rawData){
        NSString *json = [[NSString alloc] initWithData:rawData encoding:NSUTF8StringEncoding];
        
        SBJsonParser *parser = [[SBJsonParser alloc] init];
        self.queue = [[NSMutableArray alloc] initWithArray:[parser objectWithString:json]];
    }else{
        self.queue = [NSMutableArray new];
    }
}

- (void) save{
    NSString *json = [queue JSONRepresentation];
    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = [paths objectAtIndex:0];
    NSString *file = [libraryDirectory stringByAppendingString:filename];
    [[NSFileManager defaultManager] createFileAtPath:file contents:data attributes:nil];
}

@end

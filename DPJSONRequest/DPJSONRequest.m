#import "DPJSONRequest.h"
#import "DPNullRemoveUtil.h"


@implementation DPJSONRequest

#pragma mark - Request

- (void)sendJSONRequestWithCallback:(DPJSONRequestCallback)callback
{
    [self sendHTTPRequestWithCallback:^(NSHTTPURLResponse* httpUrlResponse, NSData* data, NSError* connectionError) {
        NSError* jsonError = nil;
        id jsonObject = nil;
        if (data) {
            jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            jsonObject = [DPNullRemoveUtil objectForRemoveNullObjects:jsonObject];
        }
        if (callback) {
            callback(httpUrlResponse, jsonObject, connectionError, jsonError);
        }
    }];
}

@end

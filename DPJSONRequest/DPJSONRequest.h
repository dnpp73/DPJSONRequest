#import <DPJSONRequest/DPHTTPRequest.h>


typedef void (^DPJSONRequestCallback)(NSHTTPURLResponse* httpUrlResponse, id json, NSError* connectionError, NSError* jsonError);


@interface DPJSONRequest : DPHTTPRequest

- (void)sendJSONRequestWithCallback:(DPJSONRequestCallback)callback;

@end

#import <DPJSONRequest/DPHTTPRequest.h>


typedef void (^DPHTTPStringRequestCallback)(NSHTTPURLResponse* httpUrlResponse, NSString* body, NSError* connectionError);


@interface DPHTTPStringRequest : DPHTTPRequest

- (void)sendHTTPStringRequestWithCallback:(DPHTTPStringRequestCallback)callback;

@end

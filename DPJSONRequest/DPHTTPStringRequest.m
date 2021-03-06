#import "DPHTTPStringRequest.h"


@implementation DPHTTPStringRequest

#pragma mark - Request

- (void)sendHTTPStringRequestWithCallback:(DPHTTPStringRequestCallback)callback
{
    [self sendHTTPRequestWithCallback:^(NSHTTPURLResponse* httpUrlResponse, NSData* data, NSError* connectionError) {
        if (connectionError || [httpUrlResponse isKindOfClass:[NSHTTPURLResponse class]] == NO) {
            if (callback) {
                callback(httpUrlResponse, nil, connectionError);
            }
        }
        else {
            CFStringEncoding cfEncoding = kCFStringEncodingUTF8;
            NSString* textEncodingName  = [httpUrlResponse textEncodingName];
            if (textEncodingName.length) {
                cfEncoding = CFStringConvertIANACharSetNameToEncoding((__bridge CFStringRef)textEncodingName);
            }
            NSStringEncoding encoding   = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
            NSString*        httpBody   = [[NSString alloc] initWithData:data encoding:encoding];
            if (callback) {
                callback(httpUrlResponse, httpBody, connectionError);
            }
        }
    }];
}

@end

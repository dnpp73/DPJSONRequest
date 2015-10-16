#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, DPHTTPRequestMethod) {
    DPHTTPRequestMethodGET    = 0,
    DPHTTPRequestMethodPOST   = 1,
    DPHTTPRequestMethodPUT    = 2,
    DPHTTPRequestMethodDELETE = 3,
};


typedef void (^DPHTTPRequestCallback)(NSHTTPURLResponse* httpUrlResponse, NSData* body, NSError* connectionError);


@interface DPHTTPRequest : NSObject

@property (nonatomic, copy, readonly) NSURL*               URL;
@property (nonatomic, readonly)       DPHTTPRequestMethod  method;
@property (nonatomic, copy, readonly) NSDictionary*        query;
@property (nonatomic, copy, readonly) NSDictionary*        form;
@property (nonatomic, readonly)       NSMutableURLRequest* URLRequest;
- (instancetype)initWithURLString:(NSString*)URLString method:(DPHTTPRequestMethod)method query:(NSDictionary*)query form:(NSDictionary*)form;

@property (nonatomic) BOOL feedbackNetworkActivityIndicator; // Default is YES. flag for networkActivityIndicator (only iOS)
@property (nonatomic) NSTimeInterval waitAfterConnection;    // Default is 0
@property (nonatomic) NSOperationQueue* requestQueue;        // Default is [[self class] defaultRequestOperationQueue]
@property (nonatomic) dispatch_queue_t  callbackQueue;       // Defautl is main queue

- (void)sendHTTPRequestWithCallback:(DPHTTPRequestCallback)callback;


+ (NSString*)HTTPMethodStringForRequestMethod:(DPHTTPRequestMethod)method;

+ (NSOperationQueue*)defaultRequestOperationQueue;

@end

#import "DPHTTPRequest.h"


@implementation DPHTTPRequest

#pragma mark - Initializer

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithURLString:(NSString*)URLString method:(DPHTTPRequestMethod)method query:(NSDictionary*)query form:(NSDictionary*)form
{
    self = [super init];
    if (self) {
        _method = method;
        _query  = query.copy;
        _form   = form.copy;
        
        _URL        = [[self class] URLWithURLString:URLString query:_query];
        _URLRequest = [[self class] URLRequestForURL:_URL method:_method form:_form];
        
        _callbackQueue = dispatch_get_main_queue();
    }
    return self;
}

#pragma mark -

- (NSString*)description
{
    NSMutableString* description = [NSMutableString stringWithFormat:@"<%@: %p", NSStringFromClass([self class]), self];
    [description appendFormat:@", URL: %@", _URL];
    [description appendFormat:@", Method: %@", [[self class] HTTPMethodStringForRequestMethod:_method]];
    [description appendFormat:@", queryCount: %d", (int)_query.count];
    [description appendFormat:@", formCount: %d", (int)_form.count];
    [description appendString:@">"];
    return description;
}

#pragma mark - Request

- (void)sendURLRequestWithCallback:(void (^)(NSHTTPURLResponse* httpUrlResponse, NSData* data, NSError* connectionError))callback // Private
{
    void (^requestCompletion)(NSData*, NSURLResponse*, NSError*) = ^(NSData* data, NSURLResponse* urlResponse, NSError* connectionError){
        NSHTTPURLResponse* httpUrlResponse = nil;
        if ([urlResponse isKindOfClass:[NSHTTPURLResponse class]]) {
            httpUrlResponse = (NSHTTPURLResponse*)urlResponse;
        } else {
            if (!connectionError) {
                connectionError = [NSError errorWithDomain:@"DPJSONRequest" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"URLResponse is not HTTPResponse"}];
            }
        }
        if (callback) {
            dispatch_async(_callbackQueue, ^{
                callback(httpUrlResponse, data, connectionError);
            });
        }
    };
    
    #if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    double versionNumber = NSFoundationVersionNumber_iOS_7_0;
    #elif TARGET_OS_MAC
    double versionNumber = NSFoundationVersionNumber10_9;
    #else
    double versionNumber = 1000;
    #endif
    // iOS 6.x, OSX 10.8
    if (NSFoundationVersionNumber < versionNumber) {
        [[[self class] defaultRequestOperationQueue] addOperationWithBlock:^{
            NSURLResponse* urlResponse     = nil;
            NSError*       connectionError = nil;
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
            NSData* data = [NSURLConnection sendSynchronousRequest:_URLRequest returningResponse:&urlResponse error:&connectionError];
            #pragma clang diagnostic pop
            requestCompletion(data, urlResponse, connectionError);
        }];
    }
    // iOS 7.x, OSX 10.9 or later
    else {
        [[[[self class] defaultURLSession] dataTaskWithRequest:_URLRequest completionHandler:requestCompletion] resume];
    }
}

- (void)sendHTTPRequestWithCallback:(DPHTTPRequestCallback)callback
{
    [self sendURLRequestWithCallback:^(NSHTTPURLResponse* httpUrlResponse, NSData* data, NSError* connectionError) {
        if (callback) {
            callback(httpUrlResponse, data, connectionError);
        }
    }];
}

#pragma mark - Public Class Method

+ (NSString*)HTTPMethodStringForRequestMethod:(DPHTTPRequestMethod)method
{
    NSString* methodString = nil;
    
    switch (method) {
        case DPHTTPRequestMethodGET:
            methodString = @"GET";
            break;
            
        case DPHTTPRequestMethodPOST:
            methodString = @"POST";
            break;
            
        case DPHTTPRequestMethodPUT:
            methodString = @"PUT";
            break;
            
        case DPHTTPRequestMethodDELETE:
            methodString = @"DELETE";
            break;
            
        default:
            break;
    }
    
    return methodString;
}

#pragma mark - Private Class Method

+ (NSOperationQueue*)defaultRequestOperationQueue // for iOS 6, NSURLConnection
{
    static NSOperationQueue* queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 1;
    });
    return queue;
}

+ (NSURLSession*)defaultURLSession // for iOS 7
{
    static NSURLSession* session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration* configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.HTTPMaximumConnectionsPerHost = 1;
        session = [NSURLSession sessionWithConfiguration:configuration];
    });
    return session;
}

+ (NSString*)queryStringFromQueryDictionary:(NSDictionary*)query
{
    if (query.allKeys.count == 0) {
        return nil;
    }
    
    static NSString* (^urlEncoder)(NSString*) = ^(NSString* string){
        #if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
        double versionNumber = NSFoundationVersionNumber_iOS_7_0;
        #elif TARGET_OS_MAC
        double versionNumber = NSFoundationVersionNumber10_9;
        #else
        double versionNumber = 1000;
        #endif
        // iOS 6.x, OSX 10.8
        if (NSFoundationVersionNumber < versionNumber) {
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
            return (__bridge_transfer NSString*)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, NULL, CFSTR("!*'\" ();:@&=+$,/?%#[]"), kCFStringEncodingUTF8);
            #pragma clang diagnostic pop
        }
        // iOS 7.x, OSX 10.9 or later
        else {
            return [string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"!*'\" ();:@&=+$,/?%#[]"].invertedSet];
        }
    };
    
    NSMutableString* queryString = [NSMutableString stringWithString:@"?"];
    for (NSString* key in query.allKeys) {
        [queryString appendFormat:@"%@=%@", urlEncoder(key), urlEncoder(query[key])];
        [queryString appendString:@"&"];
    }
    [queryString deleteCharactersInRange:NSMakeRange(queryString.length - 1, 1)];
    return queryString.copy;
}

+ (NSURL*)URLWithURLString:(NSString*)URLString query:(NSDictionary*)query
{
    if (URLString.length == 0) {
        return nil;
    }
    
    if (query) {
        URLString = [URLString stringByAppendingString:[self queryStringFromQueryDictionary:query]];
    }
    
    return [NSURL URLWithString:URLString];
}

+ (NSMutableURLRequest*)URLRequestForURL:(NSURL*)URL method:(DPHTTPRequestMethod)method form:(NSDictionary*)form
{
    if (!URL) {
        return nil;
    }
    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20];
    // [req addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    request.HTTPMethod = [self HTTPMethodStringForRequestMethod:method];
    
    if (form) {
        [self buildPostFormBodyForRequest:request form:form];
    }
    
    return request;
}

+ (void)buildPostFormBodyForRequest:(NSMutableURLRequest*)request form:(NSDictionary*)form
{
    if (!request) {
        return;
    }
    if (form.allKeys.count == 0) {
        return;
    }
    
    NSString* charset = (NSString*)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    
    // We don't bother to check if post data contains the boundary, since it's pretty unlikely that it does.
    CFUUIDRef uuid = CFUUIDCreate(nil);
    NSString* uuidString = (__bridge_transfer NSString*)CFUUIDCreateString(nil, uuid);
    CFRelease(uuid);
    
    NSString* stringBoundary = [NSString stringWithFormat:@"0xHxRnCeQyVzSqKCwUEe-%@", uuidString];
    
    [request addValue:[NSString stringWithFormat:@"multipart/form-data; charset=%@; boundary=%@", charset, stringBoundary] forHTTPHeaderField:@"Content-Type"];
    
    NSMutableString* postString = [NSMutableString string];
    
    [postString appendString:[NSString stringWithFormat:@"--%@\r\n", stringBoundary]];
    
    // Adds post data
    NSString* endItemBoundary = [NSString stringWithFormat:@"\r\n--%@\r\n", stringBoundary];
    __block NSUInteger i=0;
    NSUInteger count = form.count;
    [form enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop) {
        if ([key isKindOfClass:[NSString class]] == NO) {
            key = [key stringValue];
        }
        if ([obj isKindOfClass:[NSString class]] == NO) {
            obj = [obj stringValue];
        }
        [postString appendString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key]];
        [postString appendString:obj];
        i++;
        if (i != count) { // Only add the boundary if this is not the last item in the post body
            [postString appendString:endItemBoundary];
        }
    }];
    
    [postString appendString:[NSString stringWithFormat:@"\r\n--%@--\r\n", stringBoundary]];
        
    request.HTTPBody = [postString dataUsingEncoding:NSUTF8StringEncoding];
}

@end

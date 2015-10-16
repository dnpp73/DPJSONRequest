#import "DPNullRemoveUtil.h"


@implementation DPNullRemoveUtil

+ (NSArray*)arrayForRemoveNullObjects:(NSArray*)array
{
    if ([array isKindOfClass:[NSArray class]] == NO) {
        return nil;
    }
    
    NSMutableArray* mutableArray = [NSMutableArray array];
    for (id obj in array) {
        if (obj != [NSNull null]) {
            if ([obj isKindOfClass:[NSArray class]]) {
                NSArray* a = [self arrayForRemoveNullObjects:obj];
                if (a) {
                    [mutableArray addObject:a];
                }
            }
            else if ([obj isKindOfClass:[NSDictionary class]]) {
                NSDictionary* d = [self dictionaryForRemoveNullObjects:obj];
                if (d) {
                    [mutableArray addObject:d];
                }
            }
            else if (obj) {
                [mutableArray addObject:obj];
            }
        }
    }
    
    if (mutableArray.count > 0) {
        return mutableArray.copy;
    } else {
        return nil;
    }
}

+ (NSDictionary*)dictionaryForRemoveNullObjects:(NSDictionary*)dictionary
{
    if ([dictionary isKindOfClass:[NSDictionary class]] == NO) {
        return nil;
    }
    
    NSMutableDictionary* mutableDictionary = [dictionary mutableCopy];
    for (id key in dictionary.allKeys) {
        id value = mutableDictionary[key];
        if (value == [NSNull null]) {
            [mutableDictionary removeObjectForKey:key];
        }
        else if ([value isKindOfClass:[NSDictionary class]]) {
            NSDictionary* d = [self dictionaryForRemoveNullObjects:value];
            [mutableDictionary removeObjectForKey:key];
            if (d) {
                [mutableDictionary setObject:d forKey:key];
            }
        }
        else if ([value isKindOfClass:[NSArray class]]) {
            NSArray* a = [self arrayForRemoveNullObjects:value];
            [mutableDictionary removeObjectForKey:key];
            if (a) {
                [mutableDictionary setObject:a forKey:key];
            }
        }
    }
    
    if (mutableDictionary.allKeys.count > 0) {
        return mutableDictionary.copy;
    } else {
        return nil;
    }
}

+ (id)objectForRemoveNullObjects:(id)object
{
    if ([object isKindOfClass:[NSArray class]]) {
        return [self arrayForRemoveNullObjects:object];
    }
    else if ([object isKindOfClass:[NSDictionary class]]) {
        return [self dictionaryForRemoveNullObjects:object];
    }
    else if (object == [NSNull null]) {
        return nil;
    }
    else {
        return object;
    }
}

@end

#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "NSError+TCHelp.h"
#import "NSMutableDictionary+paramsSet.h"
#import "NSString+TCHelp.h"
#import "TCBaseApi.h"
#import "TCHttpManager.h"
#import "UIView+TCToast.h"

FOUNDATION_EXPORT double TCNetworkVersionNumber;
FOUNDATION_EXPORT const unsigned char TCNetworkVersionString[];

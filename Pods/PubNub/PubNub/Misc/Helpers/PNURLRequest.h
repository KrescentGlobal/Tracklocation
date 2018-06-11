#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

/**
 @brief  Useful NSURLRequest additions collection.
 
 @author Sergey Mamontov
 @since 4.0
 @copyright © 2009-2017 PubNub, Inc.
 */
@interface PNURLRequest : NSObject


///------------------------------------------------
/// @name Helper
///------------------------------------------------

/**
 @brief  Calculate actual size of the packet which will be generated by specified URL request.
 
 @param request Reference on URL request instance which store all required information which will be
                used for calculation.
 
 @return Actual (full) size of HTTP packet which will be sent to \b PubNub network.
 
 @since 4.0
 */
+ (NSInteger)packetSizeForRequest:(NSURLRequest *)request;

#pragma mark -


@end

NS_ASSUME_NONNULL_END

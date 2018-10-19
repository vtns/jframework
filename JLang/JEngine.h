//
//  JEngine.h
//  JLang
//
//  Created by tadayoshi on 2018/10/20.
//  Copyright © 2018 vtns. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum JEngineMessageType {
    JEngineMessageTypeFormatted = 1, /* formatted result array output */
    JEngineMessageTypeError = 2, /* error output */
    JEngineMessageTypeLog = 3, /* output log */
    JEngineMessageTypeAssertionFailure = 4, /* system assertion failure */
    JEngineMessageTypeExit = 5, /* exit */
    JEngineMessageTypeOutput = 6 /* output 1!:2[2 */
} JEngineMessageType;

@protocol JEngineDelegate <NSObject>
- (void)put:(const char*)message type:(JEngineMessageType)type;
- (const char*)getWithPrompt:(const char*)prompt;
@end

@interface JEngine : NSObject
@property (weak) id<JEngineDelegate> delegate;

+ (NSString*) jlibrary;
- (void*) load:(const char*)binPath;
- (int) eval:(const char*)sentence;
- (void) unload;
@end

NS_ASSUME_NONNULL_END

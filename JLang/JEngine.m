//
//  JEngine.m
//  JLang
//
//  Created by tadayoshi on 2018/10/20.
//  Copyright © 2018 vtns. All rights reserved.
//

#import "JEngine.h"

#include <stdint.h>
#include <unistd.h>

#include "j.h"
#include "jversion.h"

C* _stdcall MyJinput(J jt, C* prompt);
void _stdcall MyJoutput(J jt,int type, C* s);

static NSMutableDictionary * engines = nil;

@interface JEngine() {
    J jt;
}
@property NSData * lastSentence;
@end

@implementation JEngine

+ (void)initialize {
    engines = [NSMutableDictionary new];
}

+ (NSString*) jlibrary {
    return [[[NSBundle bundleForClass:self] resourcePath] stringByAppendingPathComponent:@"jlibrary"];
}

- (BOOL) load:(NSString*)jlibraryPath {
    
    if ([jlibraryPath hasSuffix:@"/"]) {
        jlibraryPath = [jlibraryPath substringToIndex:jlibraryPath.length-1];
    }

    NSString *homePath;
    NSRange r = [jlibraryPath rangeOfString:@"/" options: NSBackwardsSearch];
    if (r.location != NSNotFound) {
        homePath = [jlibraryPath substringToIndex:r.location];
    } else {
        homePath = jlibraryPath;
    }
    setenv("HOME", [homePath fileSystemRepresentation], 1);

    jt = JInit();
    if (!jt) return NO;
    [engines setObject:self forKey:[NSValue valueWithPointer:jt]];

    void* callbacks[] ={MyJoutput,0,MyJinput,0,(void*)SMCON};
    JSM(jt,callbacks);
  
    NSString * input = [NSString stringWithFormat:
                        @"(3 : '0!:0 y')<BINPATH,'/profile.ijs'"
                        @"[ARGV_z_=:''"
                        @"[UNAME_z_=:'Darwin'"
                        @"[LIBFILE_z_=:BINPATH_z_,'dummy.dylib'"
                        @"[BINPATH_z_=:HOMEPATH,'/Documents/j/bin'"
                        @"[INSTALLROOT_z_=:HOMEPATH,'/Documents/j'"
                        @"[HOMEPATH=.'%s'"
                        @"[IFIOS=:1", [homePath fileSystemRepresentation]];

    JDo(jt, (C*) [input UTF8String]);

    return YES;
}

- (void)unload {
    if (jt) JFree(jt);
    [engines removeObjectForKey:[NSValue valueWithPointer:jt]];
}

- (BOOL) eval:(NSString*)sentence {
    if (JDo(jt,(C*)[sentence UTF8String]))
        return NO;
    return YES;
}

@end


/* J calls for input */
C* _stdcall MyJinput(J jt, C* prompt){
    JEngine * e = [engines objectForKey:[NSValue valueWithPointer:jt]];
    if (e) {
        NSString *sentence = [e.delegate getWithPrompt:[NSString stringWithUTF8String:(const char*)prompt]];
        const char* p = [sentence UTF8String];
        e.lastSentence = [NSData dataWithBytes:p length:strlen(p)+1];
        return (C*)[e.lastSentence bytes];
    }
    return (C*) "";
}

/* J calls for output */
void _stdcall MyJoutput(J jt, int t, C* s)
{
    JEngine * e = [engines objectForKey:[NSValue valueWithPointer:jt]];
    [e.delegate put:[NSString stringWithUTF8String:(const char*)s]
               type:(JEngineMessageType)t];
}

/////////////////////

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
    jt = JInit();
    if (!jt) return NO;
    [engines setObject:self forKey:[NSValue valueWithPointer:jt]];

    void* callbacks[] ={MyJoutput,0,MyJinput,0,(void*)SMCON};
    JSM(jt,callbacks);

    char input[4096];
    *input=0;

    strcat(input,"(3 : '0!:0 y')<BINPATH,'/profile.ijs'");
    strcat(input,"[ARGV_z_=:''");
    strcat(input,"[UNAME_z_=:'Darwin'");
    strcat(input,"[BINPATH_z_=:'");
    strcat(input, [jlibraryPath fileSystemRepresentation]);
    strcat(input,"/bin'");
    strcat(input,"[LIBFILE_z_=:'");
    strcat(input, [jlibraryPath fileSystemRepresentation]);
    strcat(input, "/bin/dummy.dylib");
    strcat(input,"'");

    JDo(jt, (C*) input);

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

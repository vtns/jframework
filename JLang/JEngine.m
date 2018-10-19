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
@end

@implementation JEngine

+ (void)initialize {
    engines = [NSMutableDictionary new];
}

+ (NSString*) jlibrary {
    return [[[NSBundle bundleForClass:self] resourcePath] stringByAppendingPathComponent:@"jlibrary"];
}

- (void*) load:(const char*)binPath {
    jt = JInit();
    if (!jt) return 0;
    [engines setObject:self forKey:[NSValue valueWithPointer:jt]];

    void* callbacks[] ={MyJoutput,0,MyJinput,0,(void*)SMCON};
    JSM(jt,callbacks);

    char input[4096];
    *input=0;

    strcat(input,"(3 : '0!:0 y')<BINPATH,'/profile.ijs'");
    strcat(input,"[ARGV_z_=:''");
    strcat(input,"[UNAME_z_=:'Darwin'");
    strcat(input,"[BINPATH_z_=:'");
    strcat(input, binPath);
    strcat(input,"'");
    strcat(input,"[LIBFILE_z_=:'");
    strcat(input, binPath);
    strcat(input, "/dummy.dylib");
    strcat(input,"'");

    JDo(jt, (C*) input);

    return jt;
}

- (void)unload {
    if (jt) JFree(jt);
    [engines removeObjectForKey:[NSValue valueWithPointer:jt]];
}

- (int) eval:(const char*)sentence {
    return JDo(jt,(C*)sentence);
}

@end


/* J calls for input */
C* _stdcall MyJinput(J jt, C* prompt){
    JEngine * e = [engines objectForKey:[NSValue valueWithPointer:jt]];
    if (e) {
       return (C*) [e.delegate getWithPrompt:(const char*)prompt];
    }
    return (C*) "";
}

/* J calls for output */
void _stdcall MyJoutput(J jt, int t, C* s)
{
    JEngine * e = [engines objectForKey:[NSValue valueWithPointer:jt]];
    [e.delegate put:(const char*)s type:(JEngineMessageType)t];
}

/////////////////////

//
//  JMXGraph.mm
//  JMX
//
//  Created by xant on 1/1/11.
//  Copyright 2011 Dyne.org. All rights reserved.
//

#define __JMXV8__ 1
#import "JMXGraph.h"
#import "JMXScript.h"
#import "JMXElement.h"

@implementation JMXGraph

@synthesize uid;

- (id)init
{
    self = [super init];
    if (self) {
        uid = [[NSString stringWithFormat:@"%8x", [self hash]] retain];
    }
    return self;
}

#pragma mark V8
using namespace v8;

static Persistent<FunctionTemplate> objectTemplate;

static v8::Handle<Value>GetRootNode(Local<String> name, const AccessorInfo& info)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXGraph *document = (JMXGraph *)info.Holder()->GetPointerFromInternalField(0);
    return handleScope.Close([[document rootElement] jsObj]);
}

static v8::Handle<Value> CreateElement(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    NSString *name = @"element";
    if (args.Length()) {
        v8::String::Utf8Value value(args[0]);
        name = [NSString stringWithUTF8String:*value];
    }
    Local<Context> currentContext  = v8::Context::GetCurrent();
    JMXScript *ctx = [JMXScript getContext:currentContext];
    if (ctx) {
        JMXElement *element = [[JMXElement alloc] initWithName:name];
        Persistent<Object> jsInstance = Persistent<Object>::New([element jsObj]);
        jsInstance->SetPointerInInternalField(0, element);
        [ctx addPersistentInstance:jsInstance obj:element];
        [element release];
        return handleScope.Close(jsInstance);
    }
    return handleScope.Close(Undefined());
}  

static v8::Handle<Value> CreateComment(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    NSString *name = @"comment";
    if (args.Length()) {
        v8::String::Utf8Value value(args[0]);
        name = [NSString stringWithUTF8String:*value];
    }
    Local<Context> currentContext  = v8::Context::GetCurrent();
    JMXScript *ctx = [JMXScript getContext:currentContext];
    if (ctx) {
        JMXElement *element = [NSXMLNode commentWithStringValue:name];
        Persistent<Object> jsInstance = Persistent<Object>::New([element jsObj]);
        jsInstance->SetPointerInInternalField(0, element);
        [ctx addPersistentInstance:jsInstance obj:element];
        return handleScope.Close(jsInstance);
    }
    return handleScope.Close(Undefined());
} 

static NSXMLNode *GatherElementById(NSXMLNode *node, char *jsId)
{
    for (NSXMLNode *n in [node children]) {
        if ([n isKindOfClass:[JMXElement class]]) {
            if (strcmp([[(JMXElement *)n jsId] UTF8String], jsId) == 0)
                return n;
        }
        NSXMLNode *element = GatherElementById(n, jsId);
        if (element)
            return element;
    }
    return nil;
}

static v8::Handle<Value> GetElementById(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
   // NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    v8::String::Utf8Value jsId(args[0]);

    JMXGraph *document = (JMXGraph *)args.Holder()->GetPointerFromInternalField(0);
    NSXMLNode *element = GatherElementById(document, *jsId);
    //NSError *error = nil;
    //NSArray *nodes = [[document rootElement] nodesForXPath:[NSString stringWithFormat:@"descendant::*[attribute::id=%@]", jsId] error:&error];
    if (element) 
        return handleScope.Close([element jsObj]);
    return Undefined();
}  

- (v8::Handle<v8::Object>)jsObj
{
    //v8::Locker lock;
    HandleScope handle_scope;
    v8::Persistent<FunctionTemplate> objectTemplate = [JMXGraph jsObjectTemplate];
    v8::Handle<Object> jsInstance = objectTemplate->InstanceTemplate()->NewInstance();
    jsInstance->SetPointerInInternalField(0, self);
    return handle_scope.Close(jsInstance);
}

+ (v8::Persistent<v8::FunctionTemplate>)jsObjectTemplate
{
    HandleScope handleScope;
    
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    objectTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    objectTemplate->Inherit([super jsObjectTemplate]);
    objectTemplate->SetClassName(String::New("Graph"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    classProto->Set("createElement", FunctionTemplate::New(CreateElement));
    classProto->Set("createComment", FunctionTemplate::New(CreateComment));
    classProto->Set("getElementById", FunctionTemplate::New(GetElementById));

    
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetAccessor(String::NewSymbol("uid"), GetStringProperty, SetStringProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("documentElement"), GetRootNode);

    instanceTemplate->SetInternalFieldCount(1);
    
    return objectTemplate;
}

@end

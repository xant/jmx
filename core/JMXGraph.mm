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
#import "JMXCanvasElement.h"
#import "NSXMLNode+V8.h"

@implementation JMXGraph

@synthesize uid, headNode;

+ (Class)replacementClassForClass:(Class)currentClass {
    if ( currentClass == [NSXMLElement class] ) {
        return [JMXElement class];
    }
    return [super replacementClassForClass:currentClass];
}

/*
- (id)initWithData:(NSData *)data options:(NSUInteger)mask error:(NSError **)error
{
    
}
*/
- (id)init
{
    self = [super init];
    if (self) {
        uid = [[NSString stringWithFormat:@"%8x", [self hash]] retain];
        headNode = [[NSXMLNode alloc] initWithKind:NSXMLElementKind];
        headNode.name = @"head";
    }
    return self;
}

- (void)dealloc
{
    [uid release];
    [headNode release];
    [super dealloc];
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

static v8::Handle<Value>GetHeadNode(Local<String> name, const AccessorInfo& info)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXGraph *document = (JMXGraph *)info.Holder()->GetPointerFromInternalField(0);
    return handleScope.Close([[document headNode] jsObj]);
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
        JMXElement *element = [name isEqualToString:@"canvas"]
                            ? [[JMXCanvasElement alloc] init]
                            : [[JMXElement alloc] initWithName:name];
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
    v8::Locker lock;
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

static v8::Handle<Value> MapSet(Local<String> name, Local<Value> value, const AccessorInfo &info)
{
    v8::Locker lock;
    HandleScope handleScope;
    Local<Object> obj = Local<Object>::Cast(info.Holder()->GetHiddenValue(String::NewSymbol("map")));
    obj->Set(name, value);
    return Undefined();
}

static v8::Handle<Value> MapGet(Local<String> name, const AccessorInfo &info)
{
    v8::Locker lock;
    HandleScope handleScope;
    Local<Object> obj = Local<Object>::Cast(info.Holder()->GetHiddenValue(String::NewSymbol("map")));
    return handleScope.Close(obj->Get(name));
}

static v8::Handle<Value> GetPropertyValue(const Arguments& args)
{
    v8::Locker lock;
    HandleScope handleScope;
    if (args.Length() && args[0]->IsString()) {
        return handleScope.Close(args.Holder()->ToObject()->Get(args[0]));
    }
    return Undefined();
}

static v8::Handle<Value> GetComputedStyle(const Arguments& args)
{
    v8::Locker lock;
    HandleScope handleScope;
    Handle<ObjectTemplate> obj = ObjectTemplate::New();
    obj->Set("paddingLeft", Integer::New(0));
    obj->Set("paddingTop", Integer::New(0));
    obj->Set("borderLeft", Integer::New(0));
    obj->Set("borderTop", Integer::New(0));
    obj->Set("height", String::New("0px"));
    obj->Set("width", String::New("0px"));
    obj->Set("getPropertyValue", FunctionTemplate::New(GetPropertyValue));
    return handleScope.Close(obj->NewInstance());
}

static v8::Handle<Value> DefaultView(Local<String> name, const AccessorInfo &info)
{
    v8::Locker lock;
    HandleScope handleScope;
    Handle<ObjectTemplate> obj = ObjectTemplate::New();
    obj->Set("getComputedStyle", FunctionTemplate::New(GetComputedStyle));
    return handleScope.Close(obj->NewInstance());
}

- (v8::Handle<v8::Object>)jsObj
{
    //v8::Locker lock;
    HandleScope handle_scope;
    v8::Persistent<FunctionTemplate> objectTemplate = [JMXGraph jsObjectTemplate];
    v8::Handle<Object> jsInstance = objectTemplate->InstanceTemplate()->NewInstance();
    jsInstance->SetPointerInInternalField(0, self);
    //jsInstance->SetHiddenValue(String::NewSymbol("map"), Object::New());
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
    instanceTemplate->SetAccessor(String::NewSymbol("body"), GetRootNode); // XXX - hack
    instanceTemplate->SetAccessor(String::NewSymbol("head"), GetHeadNode); // XXX - hack

    instanceTemplate->SetAccessor(String::NewSymbol("defaultView"), DefaultView);
    //instanceTemplate->SetNamedPropertyHandler(MapGet, MapSet);
    
    instanceTemplate->SetInternalFieldCount(1);
    
    
    
    return objectTemplate;
}

@end

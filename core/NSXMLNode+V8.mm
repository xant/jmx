//
//  NSXMLNode+V8.mm
//  JMX
//
//  Created by xant on 1/4/11.
//  Copyright 2011 Dyne.org. All rights reserved.
//

#define __JMXV8__
#import "NSXMLNode+V8.h"
#import "JMXV8PropertyAccessors.h"
#import "JMXElement.h"
#import "JMXEvent.h"
#import "JMXEventListener.h"
#import "JMXScriptEntity.h"
#import "JMXAttribute.h"

JMXV8_EXPORT_NODE_CLASS(NSXMLNode);

@implementation NSXMLNode (JMXV8)

- (id)jmxInit
{
    // XXX - Note that [self initWithKind:] will implicitly call [self init]
    return [self initWithKind:NSXMLTextKind];
}


- (NSUInteger)hash
{
    return (NSUInteger)self;
}

- (NSString *)hashString
{
    return [NSString stringWithFormat:@"%d", [self hash]];
}

- (id)copyWithZone:(NSZone *)zone
{
    // we don't want copies, but we want to use such objects as keys of a dictionary
    // so we still need to conform to the 'copying' protocol,
    // but since we are to be considered 'immutable' we can adopt what described at the end of :
    // http://developer.apple.com/mac/library/documentation/cocoa/conceptual/MemoryMgmt/Articles/mmImplementCopy.html
    return [self retain];
}

#pragma mark V8

using namespace v8;

static v8::Handle<Value>GetParentNode(Local<String> name, const AccessorInfo& info)
{   
    //v8::Locker lock;
    HandleScope handleScope;
    NSXMLNode *node = (NSXMLNode *)info.Holder()->GetPointerFromInternalField(0);
    Local<Value> ret;
    id parent = [node parent];
    if (parent && [parent isKindOfClass:[NSXMLNode class]]) {
        if ([parent conformsToProtocol:@protocol(JMXV8)])
            return handleScope.Close([(id<JMXV8>)parent jsObj]);
        else
            NSLog(@"XML Element %@ is not a NSXMLNode instance", parent);
    }
    return v8::Undefined();
}

static v8::Handle<Value>GetChildNodes(Local<String> name, const AccessorInfo& info)
{   
    //v8::Locker lock;
    HandleScope handleScope;
    NSXMLNode *node = (NSXMLNode *)info.Holder()->GetPointerFromInternalField(0);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSArray *children = [node children];
    Local<Context> ctx = v8::Context::GetCurrent();
    Local<Function> constructor = v8::Local<v8::Function>::Cast(ctx->Global()->Get(String::New("NodeList")));
    if (!constructor.IsEmpty()) {        
        v8::Handle<Object> obj = info.Holder();
        v8::Handle<Object> list = constructor->NewInstance();
        for (NSXMLNode *child in children) {
            Local<Function> push = v8::Local<v8::Function>::Cast(list->Get(String::New("push")));
            v8::Handle<Value> args[1];
            args[0] = [child jsObj];
            push->Call(list, 1, args);
        }
        [pool drain];
        return handleScope.Close(list);
    } else {
        NSLog(@"Can't find constructor for class 'NodeList'");
    }
    [pool drain];
    return handleScope.Close(Undefined());
}

static v8::Handle<Value>GetFirstChild(Local<String> name, const AccessorInfo& info)
{   
    //v8::Locker lock;
    HandleScope handleScope;
    NSXMLNode *node = (NSXMLNode *)info.Holder()->GetPointerFromInternalField(0);
    return handleScope.Close([[node childAtIndex:0] jsObj]);
}

static v8::Handle<Value>GetLastChild(Local<String> name, const AccessorInfo& info)
{   
    //v8::Locker lock;
    HandleScope handleScope;
    NSXMLNode *node = (NSXMLNode *)info.Holder()->GetPointerFromInternalField(0);
    return handleScope.Close([[node childAtIndex:[node childCount]-1] jsObj]);
}

static v8::Handle<Value>GetPreviousSibling(Local<String> name, const AccessorInfo& info)
{   
    //v8::Locker lock;
    HandleScope handleScope;
    NSXMLNode *node = (NSXMLNode *)info.Holder()->GetPointerFromInternalField(0);
    NSXMLNode *sibling = [node previousSibling];
    if (sibling)
        return handleScope.Close([sibling jsObj]);
    else
        return handleScope.Close(Undefined());
}

static v8::Handle<Value>GetNextSibling(Local<String> name, const AccessorInfo& info)
{   
    //v8::Locker lock;
    HandleScope handleScope;
    NSXMLNode *node = (NSXMLNode *)info.Holder()->GetPointerFromInternalField(0);
    NSXMLNode *sibling = [node nextSibling];
    if (sibling)
        return handleScope.Close([sibling jsObj]);
    else
        return handleScope.Close(Undefined());
}

static v8::Handle<Value>GetAttributes(Local<String> name, const AccessorInfo& info)
{   
    //v8::Locker lock;
    HandleScope handleScope;
    Local<Context> ctx = v8::Context::GetCurrent();
    Local<Function> constructor = v8::Local<v8::Function>::Cast(ctx->Global()->Get(String::New("NamedNodeMap")));
    if (!constructor.IsEmpty()) {
        v8::Handle<Object> list = constructor->NewInstance();
        id holder = (id)info.Holder()->GetPointerFromInternalField(0);
        if ([holder isKindOfClass:[NSXMLElement class]]) {
            NSXMLElement *node = (NSXMLElement *)info.Holder()->GetPointerFromInternalField(0);
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            for (NSXMLNode *attr in [node attributes]) {
                Local<Function> setNamedItem = v8::Local<v8::Function>::Cast(list->Get(String::New("setNamedItem")));
                v8::Handle<Value> args[1];
                args[0] = [attr jsObj];
                setNamedItem->Call(list, 1, args);
            }
            [pool drain];
        }
        return handleScope.Close(list);
    } else {
        NSLog(@"Can't find constructor for class 'NamedNodeMap'");
    }
    return handleScope.Close(Undefined());
}

static v8::Handle<Value>GetNameSpaceURI(Local<String> name, const AccessorInfo& info)
{   
    //v8::Locker lock;
    HandleScope handleScope;
    NSXMLNode *node = (NSXMLNode *)info.Holder()->GetPointerFromInternalField(0);
    return handleScope.Close(String::New([[node URI] UTF8String]));
}

static v8::Handle<Value>GetLocalName(Local<String> name, const AccessorInfo& info)
{   
    //v8::Locker lock;
    HandleScope handleScope;
    NSXMLNode *node = (NSXMLNode *)info.Holder()->GetPointerFromInternalField(0);
    return handleScope.Close(String::New([[node localName] UTF8String]));
}

static v8::Handle<Value>GetOwnerDocument(Local<String> name, const AccessorInfo& info)
{   
    //v8::Locker lock;
    HandleScope handleScope;
    NSXMLNode *node = (NSXMLNode *)info.Holder()->GetPointerFromInternalField(0);
    return handleScope.Close([[node rootDocument] jsObj]);
}

static v8::Handle<Value>GetPrefix(Local<String> name, const AccessorInfo& info)
{   
    //v8::Locker lock;
    HandleScope handleScope;
    NSXMLNode *node = (NSXMLNode *)info.Holder()->GetPointerFromInternalField(0);
    return handleScope.Close(String::New([[node prefix] UTF8String]));
}

static v8::Handle<Value>GetBaseURI(Local<String> name, const AccessorInfo& info)
{   
    //v8::Locker lock;
    HandleScope handleScope;
    NSXMLNode *node = (NSXMLNode *)info.Holder()->GetPointerFromInternalField(0);
    return handleScope.Close(String::New([[[node rootDocument] URI] UTF8String]));
}

static v8::Handle<Value>GetTextContent(Local<String> name, const AccessorInfo& info)
{   
    //v8::Locker lock;
    HandleScope handleScope;
    NSXMLNode *node = (NSXMLNode *)info.Holder()->GetPointerFromInternalField(0);
    return handleScope.Close(String::New([[node stringValue] UTF8String]));
}

static v8::Handle<Value>GetNodeType(Local<String> name, const AccessorInfo& info)
{   
    //v8::Locker lock;
    HandleScope handleScope;
    return handleScope.Close(v8::Integer::New(1));
}

static v8::Handle<Value> InsertBefore(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    id holder = (id)args.Holder()->GetPointerFromInternalField(0);
    if ([holder isKindOfClass:[NSXMLElement class]]) {
        NSXMLElement *node = (NSXMLElement *)holder;
        NSXMLNode *newChild = (NSXMLNode *)args[0]->ToObject()->GetPointerFromInternalField(0);
        if (newChild) {
            NSUInteger index = [node childCount];
            if (!args[1]->IsUndefined()) {
                NSXMLNode *refChild = (NSXMLNode *)args[1]->ToObject()->GetPointerFromInternalField(0);
                if (refChild)
                    index = [refChild index];
            }
            if (newChild.parent)
                [newChild detach];
            [node insertChild:newChild atIndex:index];
            return handleScope.Close(args[0]->ToObject());
        } else {
            // TODO - Error Messages
        }
    }
    return handleScope.Close(Undefined());
}

static v8::Handle<Value> ReplaceChild(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    id holder = (id)args.Holder()->GetPointerFromInternalField(0);
    if ([holder isKindOfClass:[NSXMLElement class]]) {
        NSXMLElement *node = (NSXMLElement *)holder;
        NSXMLNode *newChild = (NSXMLNode *)args[0]->ToObject()->GetPointerFromInternalField(0);
        NSXMLNode *oldChild = (NSXMLNode *)args[1]->ToObject()->GetPointerFromInternalField(0);
        if (newChild && oldChild) {
            [node replaceChildAtIndex:[oldChild index] withNode:newChild];
            return handleScope.Close(args[0]->ToObject());
        } else {
            // TODO - Error Messages
        }
    }
    return handleScope.Close(Undefined());
}

static v8::Handle<Value> RemoveChild(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    id holder = (id)args.Holder()->GetPointerFromInternalField(0);
    if ([holder isKindOfClass:[NSXMLElement class]]) {
        NSXMLElement *node = (NSXMLElement *)holder;
        NSXMLNode *child = (NSXMLNode *)args[0]->ToObject()->GetPointerFromInternalField(0);
        if (child) {
            [node removeChildAtIndex:[child index]];
            return handleScope.Close(args[0]->ToObject());
        } else {
            // TODO - Error Messages
        }
    }
    return handleScope.Close(Undefined());
}

static v8::Handle<Value> AppendChild(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    id holder = (id)args.Holder()->GetPointerFromInternalField(0);
    if ([holder isKindOfClass:[NSXMLElement class]]) {
        NSXMLElement *node = (NSXMLElement *)holder;
        NSXMLNode *newChild = (NSXMLNode *)args[0]->ToObject()->GetPointerFromInternalField(0);
        if (newChild) {
            if (newChild.parent)
                [newChild detach];
            [node addChild:newChild];
            return handleScope.Close(args[0]->ToObject());
        } else {
            // TODO - Error Messages
        }
    }
    return handleScope.Close(Undefined());
}

static v8::Handle<Value> HasChildNodes(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    bool ret = false;
    NSXMLNode *node = (NSXMLNode *)args.Holder()->GetPointerFromInternalField(0);
    if (node)
        ret = [node childCount] ? true : false;
    return handleScope.Close(v8::Boolean::New(ret));
}

static v8::Handle<Value> Normalize(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    id holder = (id)args.Holder()->GetPointerFromInternalField(0);
    if (holder && [holder isKindOfClass:[NSXMLElement class]])
        [(NSXMLElement *)holder normalizeAdjacentTextNodesPreservingCDATA:YES];
    return handleScope.Close(Undefined());
}

static v8::Handle<Value> IsSupported(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    id holder = (id)args.Holder()->GetPointerFromInternalField(0);
    if (holder && [holder isKindOfClass:[NSXMLElement class]]) {
        v8::Handle<Value> subArgs[2] = { args[0], args[1] }; 
        Local<Context> ctx = v8::Context::GetCurrent();
        Local<Function> constructor = v8::Local<v8::Function>::Cast(ctx->Global()->Get(String::New("DOMImplementation")));
        if (!constructor.IsEmpty()) {
            v8::Handle<Object> domImplementation = constructor->NewInstance();
            Local<Function> hasFeature = v8::Local<v8::Function>::Cast(domImplementation->Get(String::New("hasFeature")));
            return handleScope.Close(hasFeature->Call(domImplementation, 2, subArgs));
        } else {
            NSLog(@"Can't find constructor for class 'DOMImplementation'");
        }
    }
    return handleScope.Close(v8::Boolean::New(false));
}

static v8::Handle<Value> GetFeature(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    id holder = (id)args.Holder()->GetPointerFromInternalField(0);
    if (holder && [holder isKindOfClass:[NSXMLElement class]]) {
        v8::Handle<Value> subArgs[2] = { args[0], args[1] }; 
        Local<Context> ctx = v8::Context::GetCurrent();
        Local<Function> constructor = v8::Local<v8::Function>::Cast(ctx->Global()->Get(String::New("DOMImplementation")));
        if (!constructor.IsEmpty()) {
            v8::Handle<Object> domImplementation = constructor->NewInstance();
            Local<Function> getFeature = v8::Local<v8::Function>::Cast(domImplementation->Get(String::New("getFeature")));
            return handleScope.Close(getFeature->Call(domImplementation, 2, subArgs));
        } else {
            NSLog(@"Can't find constructor for class 'DOMImplementation'");
        }
    }
    return handleScope.Close(v8::Boolean::New(false));
}

static v8::Handle<Value> IsSameNode(const Arguments& args)
{
    //v8::Locker lock;
    BOOL ret = NO;
    HandleScope handleScope;
    NSXMLNode *holder = (NSXMLNode *)args.Holder()->GetPointerFromInternalField(0);
    NSXMLNode *other = (NSXMLNode *)args[0]->ToObject()->GetPointerFromInternalField(0);
    if (other)
        ret = (holder == other) ? YES : NO;
    return handleScope.Close(v8::Boolean::New(ret));
}

static v8::Handle<Value> IsEqualNode(const Arguments& args)
{
    //v8::Locker lock;
    BOOL ret = NO;
    HandleScope handleScope;
    NSXMLNode *holder = (NSXMLNode *)args.Holder()->GetPointerFromInternalField(0);
    NSXMLNode *other = (NSXMLNode *)args[0]->ToObject()->GetPointerFromInternalField(0);
    if (other)
        ret = [holder isEqual:other];
    return handleScope.Close(v8::Boolean::New(ret));
}

static v8::Handle<Value> SetUserData(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    v8::Handle<Object> obj = args.Holder();
    if (args.Length() >= 2 && args[0]->IsString()) {
        obj->SetHiddenValue(args[0]->ToString(), args[1]);
        return handleScope.Close(args[1]);
    }
    return handleScope.Close(Undefined());
}

static v8::Handle<Value> GetUserData(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    v8::Handle<Object> obj = args.Holder();
    if (args.Length() >= 1 && args[0]->IsString())
        return handleScope.Close(obj->GetHiddenValue(args[0]->ToString()));
    return handleScope.Close(Undefined());
}

static v8::Handle<Value> LookupPrefix(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    v8::Handle<Object> obj = args.Holder();
    NSXMLNode *node = (NSXMLNode *)args.Holder()->GetPointerFromInternalField(0);
    if (node && args.Length() >= 1 && args[0]->IsString()) {
        if ([node respondsToSelector:@selector(namespaces)]) {
            v8::String::Utf8Value uri(args[0]);
            NSArray *namespaces = [node performSelector:@selector(namespaces)];
            for (NSXMLNode *ns in namespaces) {
                if ([[ns URI] isEqualTo:[NSString stringWithUTF8String:*uri]])
                    return handleScope.Close(v8::String::New([[ns prefix] UTF8String]));
            }
        }
    }
    return handleScope.Close(Undefined());
}

static v8::Handle<Value> IsDefaultNamespace(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    BOOL ret = NO;
    v8::Handle<Object> obj = args.Holder();
    NSXMLNode *node = (NSXMLNode *)args.Holder()->GetPointerFromInternalField(0);
    if (node && args.Length() >= 1 && args[0]->IsString()) {
        if ([node respondsToSelector:@selector(namespaces)]) {
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            v8::String::Utf8Value uri(args[0]);
            NSXMLNode *defaultNamespace = [NSXMLNode namespaceWithName:@"" stringValue:@""];
            if (strcmp([[defaultNamespace URI] UTF8String], *uri) == 0) 
                ret = YES;
            [pool drain];
        }
    }
    return handleScope.Close(v8::Boolean::New(ret));
}

static v8::Handle<Value> LookupNamespaceURI(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    v8::Handle<Object> obj = args.Holder();
    NSXMLNode *node = (NSXMLNode *)args.Holder()->GetPointerFromInternalField(0);
    if (node && args.Length() >= 1 && args[0]->IsString()) {
        if ([node respondsToSelector:@selector(namespaceForPrefix:)]) {
            v8::String::Utf8Value prefix(args[0]);
            NSXMLNode *ns = [node performSelector:@selector(namespaceForPrefix:) withObject:[NSString stringWithUTF8String:*prefix]];
            if (ns)
                return handleScope.Close(v8::String::New([[ns URI] UTF8String]));
        }
    }
    return handleScope.Close(Undefined());
}

/*
// DocumentPosition
const unsigned short      DOCUMENT_POSITION_DISCONNECTED = 0x01;
const unsigned short      DOCUMENT_POSITION_PRECEDING    = 0x02;
const unsigned short      DOCUMENT_POSITION_FOLLOWING    = 0x04;
const unsigned short      DOCUMENT_POSITION_CONTAINS     = 0x08;
const unsigned short      DOCUMENT_POSITION_CONTAINED_BY = 0x10;
const unsigned short      DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC = 0x20;
*/
static v8::Handle<Value> CompareDocumentPosition(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    /*
    v8::Handle<Object> obj = args.Holder();
    NSXMLNode *node = (NSXMLNode *)args.Holder()->GetPointerFromInternalField(0);
     */
    return handleScope.Close(v8::Integer::New(0x20)); // XXX
}

static void GatherElementsByName(NSXMLNode *node, char *name, NSMutableArray *elements)
{
    for (NSXMLNode *n in [node children]) {
        if (strcmp(name, "*") == 0 || (n.name && (strcmp([n.name UTF8String], name) == 0)))
            [elements addObject:n];
        GatherElementsByName(n, name, elements);
    }
}

static v8::Handle<Value> GetElementsByTagName(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    v8::Handle<Object> obj = args.Holder();
    NSXMLNode *node = (NSXMLNode *)args.Holder()->GetPointerFromInternalField(0);
    v8::String::Utf8Value name(args[0]);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSMutableArray *elements = [NSMutableArray array];
    GatherElementsByName(node, *name, elements);
    Local<Context> ctx = v8::Context::GetCurrent();
    Local<Function> constructor = v8::Local<v8::Function>::Cast(ctx->Global()->Get(String::New("NodeList")));
    if (!constructor.IsEmpty()) {
        v8::Handle<Object> list = constructor->NewInstance();
        for (NSXMLNode *element in elements) {
            Local<Function> push = v8::Local<v8::Function>::Cast(list->Get(String::New("push")));
            v8::Handle<Value> args[1];
            args[0] = [element jsObj];
            push->Call(list, 1, args);
        }
        [pool drain];
        return handleScope.Close(list);
    } else {
        NSLog(@"Can't find constructor for class 'NodeList'");
    }
    [pool drain];
    return handleScope.Close(Undefined()); // XXX
}

static v8::Handle<Value> GetAttribute(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    v8::Handle<Value> ret = Undefined();
    v8::String::Utf8Value name(args[0]);
    NSXMLNode *node = (NSXMLNode *)args.Holder()->GetPointerFromInternalField(0);
    if ([node respondsToSelector:@selector(attributeForName:)]) {
        NSXMLNode *attribute = [node performSelector:@selector(attributeForName:) withObject:[NSString stringWithUTF8String:*name]];
        if (attribute)
            ret = String::New([[attribute stringValue] UTF8String]);
    } else if ([node respondsToSelector:@selector(attributes)]) {
        NSArray *attributes = [node performSelector:@selector(attributes)];
        for (NSXMLNode *attr in attributes) {
            if (strcmp([attr.name UTF8String], *name) == 0)
                ret = String::New([[attr stringValue] UTF8String]);
        }
    }
    [pool drain];
    return handleScope.Close(ret); // XXX
}

static v8::Handle<Value> SetAttribute(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    NSXMLNode *node = (NSXMLNode *)args.Holder()->GetPointerFromInternalField(0);
    if (args.Length() > 1 && [node isKindOfClass:[NSXMLElement class]]) {
        v8::String::Utf8Value name(args[0]);
        v8::String::Utf8Value value(args[1]);
        NSString *nameString = [NSString stringWithUTF8String:*name];
        NSString *valueString = [NSString stringWithUTF8String:*value];

        NSXMLNode *attr = [(NSXMLElement *)node attributeForName:nameString];
        if (attr)
            [attr setStringValue:valueString];
        else
            [(NSXMLElement *)node addAttribute:[JMXAttribute attributeWithName:nameString
                                                                   stringValue:valueString]];
    }
    return handleScope.Close(v8::Integer::New(0x20)); // XXX
}

static v8::Handle<Value> AddEventListener(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    NSXMLNode *node = (NSXMLNode *)args.Holder()->GetPointerFromInternalField(0);
    if (args.Length() > 2 && args[0]->IsString() && args[1]->IsFunction()
        && (args[2]->IsBoolean() || args[2]->IsNumber()))
    {
        v8::String::Utf8Value type(args[0]);

        JMXEventListener *listener = [[[JMXEventListener alloc] init] autorelease];
        listener.function = Persistent<Function>::New(Handle<Function>::Cast(args[1]));
        listener.target = node;
        listener.capture = args[2]->IsUndefined() ? NO : args[2]->BooleanValue();
        Local<Context> context = v8::Context::GetCalling();
        Local<Object> globalObject  = context->Global();
        v8::Local<v8::Object> entityObj = globalObject->Get(String::New("scriptEntity"))->ToObject();
        JMXScriptEntity *entity = (JMXScriptEntity *)entityObj->GetPointerFromInternalField(0);
        JMXScript *scriptContext = entity.jsContext;
        [scriptContext addListener:listener forEvent:[NSString stringWithUTF8String:*type]];
    }
    return handleScope.Close(Undefined()); // XXX
}

static v8::Handle<Value> RemoveEventListener(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    NSXMLNode *node = (NSXMLNode *)args.Holder()->GetPointerFromInternalField(0);
    if (args.Length() > 2 && args[0]->IsString() && args[1]->IsObject()
        && (args[2]->IsBoolean() || args[2]->IsNumber()))
    {
        v8::String::Utf8Value type(args[0]);
        
        Handle<Object> obj = args[1]->ToObject();
        JMXEventListener *listener = (JMXEventListener *)obj->GetPointerFromInternalField(0);
        BOOL capture = args[2]->BooleanValue();
        Local<Context> context = v8::Context::GetCalling();
        Local<Object> globalObject  = context->Global();
        v8::Local<v8::Object> entityObj = globalObject->Get(String::New("scriptEntity"))->ToObject();
        JMXScriptEntity *entity = (JMXScriptEntity *)entityObj->GetPointerFromInternalField(0);
        JMXScript *scriptContext = entity.jsContext;
        [scriptContext removeListener:listener forEvent:[NSString stringWithUTF8String:*type]];
    }
    return handleScope.Close(Undefined()); // XXX
}

static v8::Handle<Value> DispatchEvent(const Arguments& args)
{
    //v8::Locker lock;
    BOOL ret = NO;
    HandleScope handleScope;
    NSXMLNode *node = (NSXMLNode *)args.Holder()->GetPointerFromInternalField(0);
    if (args.Length() && args[0]->IsObject())
    {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        v8::String::Utf8Value type(args[0]);
        Handle<Object> obj = args[0]->ToObject();
        JMXEvent *event = (JMXEvent *)obj->GetPointerFromInternalField(0);
        Local<Context> context = v8::Context::GetCalling();
        Local<Object> globalObject  = context->Global();
        v8::Local<v8::Object> entityObj = globalObject->Get(String::New("scriptEntity"))->ToObject();
        JMXScriptEntity *entity = (JMXScriptEntity *)entityObj->GetPointerFromInternalField(0);
        JMXScript *scriptContext = entity.jsContext;
        ret = [scriptContext dispatchEvent:event];
        [pool release];
    }
    return handleScope.Close(v8::Boolean::New(ret)); // XXX
}

- (void)jsInit:(NSValue *)argsValue
{
    v8::Arguments *args = (v8::Arguments *)[argsValue pointerValue];
    if (args->Length() >= 1) {
        v8::String::Utf8Value name((*args)[0]->ToString());
        self.name = [NSString stringWithUTF8String:*name];
    }
}

+ (v8::Persistent<FunctionTemplate>)jsObjectTemplate
{
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    objectTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    objectTemplate->SetClassName(String::New("Node"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    // set instance methods
    classProto->Set("insertBefore", FunctionTemplate::New(InsertBefore));
    classProto->Set("replaceChild", FunctionTemplate::New(ReplaceChild));
    classProto->Set("removeChild", FunctionTemplate::New(RemoveChild));
    classProto->Set("appendChild", FunctionTemplate::New(AppendChild));
    classProto->Set("hasChildNodes", FunctionTemplate::New(HasChildNodes));
    //classProto->Set("cloneNode", FunctionTemplate::New(CloneNode));
    classProto->Set("normalize", FunctionTemplate::New(Normalize));
    classProto->Set("isSupported", FunctionTemplate::New(IsSupported));
    // Introduced in DOM Level 3:
    classProto->Set("isSameNode", FunctionTemplate::New(IsSameNode));
    classProto->Set("isEqualNode", FunctionTemplate::New(IsEqualNode));
    classProto->Set("setUserData", FunctionTemplate::New(SetUserData));
    classProto->Set("getUserData", FunctionTemplate::New(GetUserData));
    classProto->Set("getFeature", FunctionTemplate::New(GetFeature));
    classProto->Set("lookupPrefix", FunctionTemplate::New(LookupPrefix));
    classProto->Set("getElementsByTagName", FunctionTemplate::New(GetElementsByTagName));
    classProto->Set("getAttribute", FunctionTemplate::New(GetAttribute));
    classProto->Set("setAttribute", FunctionTemplate::New(SetAttribute));
    classProto->Set("addEventListener", FunctionTemplate::New(AddEventListener));
    classProto->Set("removeEventListener", FunctionTemplate::New(RemoveEventListener));
    classProto->Set("dispatchEvent", FunctionTemplate::New(DispatchEvent));
    classProto->Set("isDefaultNamespace", FunctionTemplate::New(IsDefaultNamespace));
    classProto->Set("lookupNamespaceURI", FunctionTemplate::New(LookupNamespaceURI));
    classProto->Set("compareDocumentPosition", FunctionTemplate::New(CompareDocumentPosition));
    
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    
    // set instance accessors
    instanceTemplate->SetAccessor(String::NewSymbol("name"), GetStringProperty, SetStringProperty);

    // DOM Related accessors
    instanceTemplate->SetAccessor(String::NewSymbol("nodeType"), GetNodeType);
    instanceTemplate->SetAccessor(String::NewSymbol("parentNode"), GetParentNode);
    instanceTemplate->SetAccessor(String::NewSymbol("childNodes"), GetChildNodes);
    instanceTemplate->SetAccessor(String::NewSymbol("firstChild"), GetFirstChild);
    instanceTemplate->SetAccessor(String::NewSymbol("lastChild"), GetLastChild);
    instanceTemplate->SetAccessor(String::NewSymbol("previousSibling"), GetPreviousSibling);
    instanceTemplate->SetAccessor(String::NewSymbol("nextSibling"), GetNextSibling);
    instanceTemplate->SetAccessor(String::NewSymbol("attributes"), GetAttributes);
    instanceTemplate->SetAccessor(String::NewSymbol("namespaceURI"), GetNameSpaceURI);
    instanceTemplate->SetAccessor(String::NewSymbol("localName"), GetLocalName);
    instanceTemplate->SetAccessor(String::NewSymbol("ownerDocument"), GetOwnerDocument);
    instanceTemplate->SetAccessor(String::NewSymbol("prefix"), GetPrefix);
    instanceTemplate->SetAccessor(String::NewSymbol("baseURI"), GetBaseURI);
    instanceTemplate->SetAccessor(String::NewSymbol("textContent"), GetTextContent);
    
    // XXX - JMX addition : the 'value' accessor is not defined by the DOM spec
    instanceTemplate->SetAccessor(String::NewSymbol("value"), GetTextContent);    

    NSDebug(@"JMXNode objectTemplate created");
    return objectTemplate;
}

static void JMXNodeJSDestructor(Persistent<Value> object, void *parameter)
{
    HandleScope handle_scope;
    v8::Locker lock;
    id obj = static_cast<id>(parameter);
    NSDebug(@"V8 WeakCallback (%@) called ", obj);
    [obj release];
    if (!object.IsEmpty()) {
        object.ClearWeak();
        object.Dispose();
        object.Clear();
    }
}

- (v8::Handle<v8::Object>)jsObj
{
    //v8::Locker lock;
    HandleScope handle_scope;
    v8::Handle<FunctionTemplate> objectTemplate = [[self class] jsObjectTemplate];
    v8::Persistent<Object> jsInstance = Persistent<Object>::New(objectTemplate->InstanceTemplate()->NewInstance());
    jsInstance.MakeWeak([self retain], JMXNodeJSDestructor);
    jsInstance->SetPointerInInternalField(0, self);
    //[ctx addPersistentInstance:jsInstance obj:self];
    return handle_scope.Close(jsInstance);
}

+ (void)jsRegisterClassMethods:(v8::Handle<v8::FunctionTemplate>)constructor
{
    // do nothing for now
}

@end

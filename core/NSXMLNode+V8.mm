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

@implementation NSXMLNode (JMXV8)


#pragma mark V8

using namespace v8;

static Persistent<FunctionTemplate> objectTemplate;

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

+ (v8::Persistent<FunctionTemplate>)jsObjectTemplate
{
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    objectTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    //objectTemplate->Inherit([super jsObjectTemplate]);
    objectTemplate->SetClassName(String::New("Node"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    // set instance methods
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    
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

    
    /*
     Element            createElement(in DOMString tagName)
     raises(DOMException);
     DocumentFragment   createDocumentFragment();
     Text               createTextNode(in DOMString data);
     Comment            createComment(in DOMString data);
     CDATASection       createCDATASection(in DOMString data)
     raises(DOMException);
     ProcessingInstruction createProcessingInstruction(in DOMString target, 
     in DOMString data)
     raises(DOMException);
     Attr               createAttribute(in DOMString name)
     raises(DOMException);
     EntityReference    createEntityReference(in DOMString name)
     raises(DOMException);
     NodeList           getElementsByTagName(in DOMString tagname);
     // Introduced in DOM Level 2:
     Node               importNode(in Node importedNode, 
     in boolean deep)
     raises(DOMException);
     // Introduced in DOM Level 2:
     Element            createElementNS(in DOMString namespaceURI, 
     in DOMString qualifiedName)
     raises(DOMException);
     // Introduced in DOM Level 2:
     Attr               createAttributeNS(in DOMString namespaceURI, 
     in DOMString qualifiedName)
     raises(DOMException);
     // Introduced in DOM Level 2:
     NodeList           getElementsByTagNameNS(in DOMString namespaceURI, 
     in DOMString localName);
     // Introduced in DOM Level 2:
     Element            getElementById(in DOMString elementId);
     
     
     // Introduced in DOM Level 3:
     Node               adoptNode(in Node source)
     raises(DOMException);
     
     // Introduced in DOM Level 3:
     void               normalizeDocument();
     // Introduced in DOM Level 3:
     Node               renameNode(in Node n, 
     in DOMString namespaceURI, 
     in DOMString qualifiedName)
     raises(DOMException);
     
     */
    NSLog(@"JMXNode objectTemplate created");
    return objectTemplate;
}

- (v8::Handle<v8::Object>)jsObj
{
    //v8::Locker lock;
    HandleScope handle_scope;
    v8::Handle<FunctionTemplate> objectTemplate = [NSXMLNode jsObjectTemplate];
    v8::Handle<Object> jsInstance = objectTemplate->InstanceTemplate()->NewInstance();
    jsInstance->SetPointerInInternalField(0, self);
    return handle_scope.Close(jsInstance);
}

+ (void)jsRegisterClassMethods:(v8::Handle<v8::FunctionTemplate>)constructor
{
    // do nothing for now
}

@end

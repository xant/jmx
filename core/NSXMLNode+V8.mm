//
//  NSXMLNode+V8.mm
//  JMX
//
//  Created by xant on 1/4/11.
//  Copyright 2011 Dyne.org. All rights reserved.
//

#define __JMXV8__
#import "NSXMLNode+V8.h"

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
    // DOM Related accessors
    instanceTemplate->SetAccessor(String::NewSymbol("nodeType"), GetNodeType);
    instanceTemplate->SetAccessor(String::NewSymbol("parentNode"), GetParentNode);
    /*
     instanceTemplate->SetAccessor(String::NewSymbol("childNodes"), GetChildNodes);
     instanceTemplate->SetAccessor(String::NewSymbol("firstChild"), GetFirstChild);
     instanceTemplate->SetAccessor(String::NewSymbol("lastChild"), GetLastChild);
     instanceTemplate->SetAccessor(String::NewSymbol("previousSibling"), GetPreviousSibling);
     instanceTemplate->SetAccessor(String::NewSymbol("nextSibling"), GetNextSibling);
     instanceTemplate->SetAccessor(String::NewSymbol("attributes"), GetAttributes);
     instanceTemplate->SetAccessor(String::NewSymbol("ownerDocument"), GetOwnerDocument);
     instanceTemplate->SetAccessor(String::NewSymbol("namespaceURI"), GetNameSpaceURI);
     instanceTemplate->SetAccessor(String::NewSymbol("prefix"), GetPrefix);
     instanceTemplate->SetAccessor(String::NewSymbol("localName"), GetLocalName);
     instanceTemplate->SetAccessor(String::NewSymbol("baseURI"), GetBaseURI);
     instanceTemplate->SetAccessor(String::NewSymbol("textContent"), GetTextContent);
     
     
     
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

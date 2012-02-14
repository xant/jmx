//
//  JMXCDATA.mm
//  JMX
//
//  Created by xant on 1/5/11.
//  Copyright 2011 Dyne.org. All rights reserved.
//

#define __JMXV8__
#import "JMXCDATA.h"
#import "JMXElement.h"

JMXV8_EXPORT_NODE_CLASS(JMXCDATA);

using namespace v8;

@implementation JMXCDATA

@synthesize data;

- (id)jmxInit
{
    return [super initWithKind:NSXMLTextKind options:NSXMLNodeIsCDATA];
}

- (id)initWithKind:(NSXMLNodeKind)kind
{
    return [super initWithKind:NSXMLTextKind options:NSXMLNodeIsCDATA];
}


- (id)initWithKind:(NSXMLNodeKind)kind options:(NSUInteger)options
{
    return [super initWithKind:NSXMLTextKind options:NSXMLNodeIsCDATA];
}

- (NSXMLNodeKind)kind
{
    return NSXMLTextKind;
}

static v8::Handle<Value> GetData(Local<String> name, const AccessorInfo& info)
{   
    //v8::Locker lock;
    HandleScope handleScope;
    JMXCDATA *cdata = (JMXCDATA *)info.Holder()->GetPointerFromInternalField(0);
    if (cdata) {
        NSData *data = cdata.data;
        return handleScope.Close(v8::String::New((char *)[data bytes], [data length]));
    }
    return handleScope.Close(Undefined());
}

void SetData(Local<String> name, Local<Value> value, const AccessorInfo& info)
{   
    //v8::Locker lock;
    HandleScope handleScope;
    JMXCDATA *cdata = (JMXCDATA *)info.Holder()->GetPointerFromInternalField(0);
    if (!value->IsString()) {
        NSLog(@"Bad parameter (not string) passed to JMXCData.SetData()");
        return;
    }
    String::Utf8Value str(value->ToString());
    Local<Value> ret;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    cdata.data = [NSData dataWithBytes:*str length:strlen(*str)];
    [pool drain];
}

static v8::Handle<Value> GetLength(Local<String> name, const AccessorInfo& info)
{   
    //v8::Locker lock;
    HandleScope handleScope;
    JMXCDATA *cdata = (JMXCDATA *)info.Holder()->GetPointerFromInternalField(0);
    if (cdata) {
        NSData *data = cdata.data;
        return handleScope.Close(v8::Integer::New([data length]));
    }
    return handleScope.Close(Undefined());
}

static v8::Handle<Value> SubstringData(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXCDATA *cdata = (JMXCDATA *)args.Holder()->GetPointerFromInternalField(0);
    v8::Handle<Integer> offset = args[0]->ToInteger();
    v8::Handle<Integer> count = args[1]->ToInteger();
    char *data = (char *)malloc(count->Value());
    [cdata.data getBytes:&data range:NSMakeRange(offset->Value(), count->Value())];
    v8::Handle<String> outString = String::New(data, count->Value());
    free(data);
    return handleScope.Close(outString);
}

static v8::Handle<Value> AppendData(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXCDATA *cdata = (JMXCDATA *)args.Holder()->GetPointerFromInternalField(0);
    v8::String::Utf8Value str(args[0]);
    size_t newLen = strlen(*str);
    NSUInteger oldLen = [cdata.data length];
    char *data = (char *)malloc(oldLen + newLen);
    [cdata.data getBytes:data];
    memcpy(data + oldLen, *str, newLen);
    cdata.data = [NSData dataWithBytesNoCopy:data length:(oldLen + newLen) freeWhenDone:YES];
    return handleScope.Close(Undefined());
}

static v8::Handle<Value> InsertData(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXCDATA *cdata = (JMXCDATA *)args.Holder()->GetPointerFromInternalField(0);
    uint64_t offset = args[0]->ToInteger()->Value();
    v8::String::Utf8Value str(args[1]);
    size_t newLen = strlen(*str);
    NSUInteger oldLen = [cdata.data length];
    char *data = (char *)malloc(oldLen + newLen);
    [cdata.data getBytes:data length:offset];
    memcpy(data + offset, *str, newLen);
    [cdata.data getBytes:(data + offset + newLen) range:NSMakeRange(offset, (oldLen - offset))];
    cdata.data = [NSData dataWithBytesNoCopy:data length:(oldLen + newLen) freeWhenDone:YES];
    return handleScope.Close(Undefined());
}

static v8::Handle<Value> DeleteData(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXCDATA *cdata = (JMXCDATA *)args.Holder()->GetPointerFromInternalField(0);
    uint64_t offset = args[0]->ToInteger()->Value();
    uint64_t count = args[1]->ToInteger()->Value();
    NSUInteger oldLen = [cdata.data length];
    char *data = (char *)malloc(oldLen - count);
    [cdata.data getBytes:data length:offset];
    [cdata.data getBytes:(data + offset) range:NSMakeRange(offset + count, (oldLen - offset - count))];
    cdata.data = [NSData dataWithBytesNoCopy:data length:(oldLen - count) freeWhenDone:YES];
    return handleScope.Close(Undefined());
}

static v8::Handle<Value> ReplaceData(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXCDATA *cdata = (JMXCDATA *)args.Holder()->GetPointerFromInternalField(0);
    uint64_t offset = args[0]->ToInteger()->Value();
    uint64_t count = args[1]->ToInteger()->Value();
    v8::String::Utf8Value str(args[2]);
    // TODO - check if (strlen(*str) >= count)
    NSUInteger oldLen = [cdata.data length];
    char *data = (char *)malloc(oldLen);
    [cdata.data getBytes:data length:offset];
    memcpy(data + offset, *str, count);
    [cdata.data getBytes:(data + offset + count) range:NSMakeRange(offset + count, (oldLen - offset - count))];
    cdata.data = [NSData dataWithBytesNoCopy:data length:oldLen freeWhenDone:YES];
    return handleScope.Close(Undefined());
}

+ (v8::Persistent<FunctionTemplate>)jsObjectTemplate
{
    //v8::Locker lock;
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    objectTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    objectTemplate->Inherit([super jsObjectTemplate]);
    objectTemplate->SetClassName(String::New("CharacterData"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();

    // set instance methods
    classProto->Set("substringData", FunctionTemplate::New(SubstringData));
    classProto->Set("appendData", FunctionTemplate::New(AppendData));
    classProto->Set("deleteData", FunctionTemplate::New(DeleteData));

    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    
    // Add accessors for each of the fields of the entity.
    instanceTemplate->SetAccessor(String::NewSymbol("data"), GetData, SetData);
    instanceTemplate->SetAccessor(String::NewSymbol("length"), GetLength);
    
    if ([self respondsToSelector:@selector(jsObjectTemplateAddons:)])
        [self jsObjectTemplateAddons:objectTemplate];
    NSLog(@"JMXCDATA objectTemplate created");
    return objectTemplate;
}

static void JMXCDataJSDestructor(Persistent<Value> object, void *parameter)
{
    HandleScope handle_scope;
    v8::Locker lock;
    JMXCDATA *obj = static_cast<JMXCDATA *>(parameter);
    //NSLog(@"V8 WeakCallback (Color) called ");
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
    v8::Handle<FunctionTemplate> objectTemplate = [JMXCDATA jsObjectTemplate];
    v8::Persistent<Object> jsInstance = Persistent<Object>::New(objectTemplate->InstanceTemplate()->NewInstance());
    jsInstance.MakeWeak([self retain], JMXCDataJSDestructor);
    jsInstance->SetPointerInInternalField(0, self);
    return handle_scope.Close(jsInstance);
}

@end

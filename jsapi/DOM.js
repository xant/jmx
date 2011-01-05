/**
 * @fileoverview
 * This file defines all DOM-related additions.
 * 
 */

// Allow to use inheritance when defining new classes directly from javascript
// TODO - perhaps it could just be bound to the v8::FunctionTemplate->Inherit()
//        method which is available in native code
Function.prototype.inherits = function inherit(parent) {
    for(var prop in parent) {
        setter = new Function("val", "return this.prototype.class." + prop + " = val;");
        this.__defineSetter__(prop, setter);
        setter.name = prop;
        
        getter = new Function("return this.prototype.class." + prop + ";");
        this.__defineGetter__(prop, getter);
        getter.name = prop;
    }
    this.prototype = new parent;
    this.prototype.class = parent;
    this.prototype.parent = this.prototype;
}

// extend the base Array class to allow 'stringifying' them
Array.prototype.toString = function() {
    out = "{ ";
    for (i = 0; i < nodes.length; i++) {
        if (i > 0)
            out += ", ";
        out += this[i];
    }
    out += " }";
    return out;
}

// ExceptionCode
INDEX_SIZE_ERR                 = 1;
DOMSTRING_SIZE_ERR             = 2;
HIERARCHY_REQUEST_ERR          = 3;
WRONG_DOCUMENT_ERR             = 4;
INVALID_CHARACTER_ERR          = 5;
NO_DATA_ALLOWED_ERR            = 6;
NO_MODIFICATION_ALLOWED_ERR    = 7;
NOT_FOUND_ERR                  = 8;
NOT_SUPPORTED_ERR              = 9;
INUSE_ATTRIBUTE_ERR            = 10;
// Introduced in DOM Level 2:
INVALID_STATE_ERR              = 11;
// Introduced in DOM Level 2:
SYNTAX_ERR                     = 12;
// Introduced in DOM Level 2:
INVALID_MODIFICATION_ERR       = 13;
// Introduced in DOM Level 2:
NAMESPACE_ERR                  = 14;
// Introduced in DOM Level 2:
INVALID_ACCESS_ERR             = 15;
// Introduced in DOM Level 3:
VALIDATION_ERR                 = 16;
// Introduced in DOM Level 3:
TYPE_MISMATCH_ERR              = 17;
function DOMException(code) {
    this.code = code;
    this.number = code;
    this.message = "DOM Exception code: " + code;
    this.name = "DOMException";
};
DOMException.inherits(Error);

function DOMString() {
}
DOMString.inherits(String);

// Introduced in DOM Level 3:
function DOMStringList() {
    this.item = function(index) {
        return this[index];
    }
    this.contains = function(str) {
        for (i = 0; i < this.length; i++)
            if (this[i] == str)
                return true;
        return false;
    }
    this.name = "DOMStringList";
}
DOMStringList.inherits(Array);

// Introduced in DOM Level 3:
function NameList() {    
    this.addNS = function(namespaceURI, name) {
        this[name] = namespaceURI;
    }
    
    this.removeNS = function(namespaceURI, name) {
        if (this[name] == namespaceURI)
            delete this[name];
    }
    
    this.removeName = function(name) {
        delete this[name];
    }
    
    this.getName = function(index) {
        realIndex = index * 2;
        return this[realIndex];
    }
    this.getNamespaceURI = function(index) {
        realIndex = index * 2 + 1;
        return this[index];
    }
    this.contains = function(str) {
        if (this[str])
            return true;
        return false;
    }
    this.containsNS = function(namespaceURI, name) {
        if (this[name] == namespaceURI)
            return true;
        return false;
    }
}
NameList.inherits(Array);

// Introduced in DOM Level 3:
function DOMImplementationList() {
    this.item = function(index) {
        return this[index];
    }
    this.name = "DOMImplementationList";
}
DOMImplementationList.inherits(Array);

function DOMImplementation() {
    this.hasFeature = function(feature, version) {
        if (feature == "Core" || feature == "XML") {
            if (version <= 3.0)
                return true;
        }
        return false;
    }
    
    this.createDocumentType = function(qualifiedName, publicId, systemId) {
        // TODO - implement
    }
    
    this.createDocument = function(namespaceURI, qualifiedName, doctype) {
        // TODO - implement
    }
    
    this.getFeature = function(feature, version) {
        // TODO - implement
    }
}

// Introduced in DOM Level 3:
function DOMImplementationSource() {
    this.getDOMImplementation = function(features) {
        // TODO - implement
    }
    
    this.getDOMImplementationList = function(features) {
        // TODO - implement
    }
    this.name = "DOMImplementationSource";
}
DOMImplementationSource.inherits(Array);

// NodeList interface (extends Array)
// http://www.w3.org/TR/2004/REC-DOM-Level-3-Core-20040407/core.html#ID-536297177
function NodeList()
{
    this.item = function(index) {
        return this[index];
    }
    this.name = "NodeList";
}
NodeList.inherits(Array);


function NamedNodeMap() {
    this.getNamedItem = function(name) {
        return this[name];
    }
    
    this.setNamedItem = function(arg) {
        if (this.readonly) {// XXX - readonly doesn't exist yet
            throw new DOMException(NO_MODIFICATION_ALLOWED_ERR);
            return null;
        }
        if (arg.ownerDocument != this.ownerDocument) {
            throw new DOMException(WRONG_DOCUMENT_ERR);
            return null;
        }
        // XXX MISSING EXCEPTIONS: INUSE_ATTRIBUTE_ERR , HIERARCHY_REQUEST_ERR
        if (this[arg.name] && arg == this[arg.name])// XXX - does comparison work as expected?
            return null;
        
        replaced = this[arg.name];
        this[arg.name] = arg;
        return replaced;
    }
    

    this.removeNamedItem = function(name) {
        if (readonly) {// XXX - readonly doesn't exist yet
            throw new DOMException(NO_MODIFICATION_ALLOWED_ERR);
            return null;
        }
        if (this[name]) {
            removed = this[name];
            delete this[name];
            return removed;
        } else {
            throw new DOMException(NOT_FOUND_ERR);
        }
        return null;
    }
    
    this.item = function(index) {
        realIndex = index * 2 + 1;
        return this[realIndex];
    }
    
    // Introduced in DOM Level 2:
    this.getNamedItemNS = function(namespaceURI, localName) {
        key = namespaceURI + ":" + localName;
        return this[key];
    }
    
    // Introduced in DOM Level 2:
    this.setNamedItemNS = function(arg) {
        key = arg.namespaceURI + ":" + arg.localName;
        if (readonly) {// XXX - readonly doesn't exist yet
            throw new DOMException(NO_MODIFICATION_ALLOWED_ERR);
            return null;
        }
        if (arg.ownerDocument != this.ownerDocument) {
            throw new DOMException(WRONG_DOCUMENT_ERR);
            return null;
        }
        // XXX MISSING EXCEPTIONS: INUSE_ATTRIBUTE_ERR , HIERARCHY_REQUEST_ERR
        if (this[key] && arg == this[key]) // XXX - does comparison work as expected?
            return null;
        replaced = this[key];
        this[key] = arg;
        return replaced;
    }
    
    // Introduced in DOM Level 2:
    this.removeNamedItemNS = function(namespaceURI, localName) {
        key = namespaceURI + ":" + localName;
        return this.removeNamedItem(key);
    }
};
NamedNodeMap.inherits(NodeList);

function DocumentFragment() {
    
}
DocumentFragment.inherits(Node);


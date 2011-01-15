/**
 * @fileoverview
 * This file defines all DOM-related additions.
 * 
 */

/** 
 * Addon function to allow inheritance when defining new classes directly from javascript
 * @addon
 */
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
    this.prototype.toString = function() {
        return this.__className__;
    }
}

/*
String.prototype.toLowerCase = function()
{
    return this; // TODO - implement
}
*/

/**
 * Extend the base Array class to allow 'stringifying' them
 * (so that "echo(array_variable)" will dump its content)
 * @addon
 */
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

/**
 * ExceptionCodes
 */
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
    /**
     * @private
     */
    Object.defineProperty(this, "__className__", { value: "DOMException", writable: false, enumerable: false });
    Object.defineProperty(this, "code", { value: code, writable: false, enumerable: true });
    Object.defineProperty(this, "number", { value: code, writable: false, enumerable: true });
    Object.defineProperty(this, "message", { value: "DOM Exception code: " + code, writable: false, enumerable: true });
    Object.defineProperty(this, "name", { value: "DOMException", writable: false, enumerable: true });
};
DOMException.inherits(Error);

/**
 * DOMString
 * @constructor
 * @param {String} string The string
 * @base String
 * @class DOM-compliant string
 */
function DOMString(string) {
    /**
     * @private
     */
    Object.defineProperty(this, "__className__", { value: "DOMString", writable: false, enumerable: false });

}
DOMString.inherits(String);

/**
 * DOMStringList
 * @constructor
 * @base Array
 * @class DOM-compliant list of strings
 * Introduced in DOM Level 3
 */
function DOMStringList() {
    /**
     * @private
     */
    Object.defineProperty(this, "__className__", { value: "DOMStringList", writable: false, enumerable: false });
    
    this.item = function(index) {
        return this[index];
    }
    this.contains = function(str) {
        for (i = 0; i < this.length; i++)
            if (this[i] == str)
                return true;
        return false;
    }
    Object.defineProperty(this, "name", { value: "DOMStringList", writable: false, enumerable: true });
}
DOMStringList.inherits(Array);

/**
 * NameList
 * @constructor
 * @base Array
 * @class DOM-compliant list of namespaces
 * Introduced in DOM Level 3
 */
function NameList() {
    /**
     * @private
     */
    Object.defineProperty(this, "__className__", { value: "NameList", writable: false, enumerable: false });

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

/**
 * DOMImplementationList
 * @constructor
 * @base Array
 * @class The DOMImplementationList interface provides the abstraction 
 * of an ordered collection of DOM implementations, without defining or 
 * constraining how this collection is implemented. The items in the 
 * DOMImplementationList are accessible via an integral index, starting from 0
 * Introduced in DOM Level 3
 */
function DOMImplementationList() {
    /**
     * @private
     */
    Object.defineProperty(this, "__className__", { value: "DOMImplementationList", writable: false, enumerable: false });

    this.item = function(index) {
        return this[index];
    }
    Object.defineProperty(this, "name", { value: "DOMImplementationList", writable: false, enumerable: false });
}
DOMImplementationList.inherits(Array);

/**
 * DOMImplementation
 * @constructor
 * @class The DOMImplementation interface provides a number of methods 
 * for performing operations that are independent of any particular 
 * instance of the document object model.
 * Introduced in DOM Level 3
 */
function DOMImplementation() {
    /**
     * @private
     */
    Object.defineProperty(this, "__className__", { value: "DOMImplementation", writable: false, enumerable: false });

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


/**
 * DOMImplementationSource
 * @constructor
 * @class The DOMImplementationSource interface permits 
 * to supply one or more implementations, based upon requested 
 * features and versions, as specified in DOM Features.
 * Each implemented DOMImplementationSource object is listed in 
 * the binding-specific list of available sources so that 
 * its DOMImplementation objects are made available.
 * Introduced in DOM Level 3
 */
function DOMImplementationSource() {
    /**
     * @private
     */
    Object.defineProperty(this, "__className__", { value: "DOMImplementationSource", writable: false, enumerable: false });
    
    this.getDOMImplementation = function(features) {
        // TODO - implement
    }
    
    this.getDOMImplementationList = function(features) {
        // TODO - implement
    }
    Object.defineProperty(this, "name", { value: "DOMImplementationSource", writable: false, enumerable: true });
}

/**
 * NodeList
 * @constructor
 * @class The NodeList interface provides the abstraction of an ordered collection 
 * of nodes, without defining or constraining how this collection is implemented. 
 * NodeList objects in the DOM are live.
 * The items in the NodeList are accessible via an integral index, starting from 0.
 * @base Array
 */
function NodeList()
{
    /**
     * @private
     */
    Object.defineProperty(this, "__className__", { value: "NodeList", writable: false, enumerable: false });

    this.item = function(index) {
        return this[index];
    }
    Object.defineProperty(this, "name", { value: "NodeList", writable: false, enumerable: true });
}
NodeList.inherits(Array);

/**
 * NamedNodeMap
 * @constructor
 * @class Objects implementing the NamedNodeMap interface are used
 * to represent collections of nodes that can be accessed by name.
 * Note that NamedNodeMap does not inherit from NodeList
 * NamedNodeMaps are not maintained in any particular order.
 * Objects contained in an object implementing NamedNodeMap may 
 * also be accessed by an ordinal index, but this is simply to allow
 * convenient enumeration of the contents of a NamedNodeMap, 
 * and does not imply that the DOM specifies an order to these Nodes.
 * NamedNodeMap objects in the DOM are live.
 * @base Array
 */
function NamedNodeMap() {
    /**
     * @private
     */
    Object.defineProperty(this, "__className__", { value: "NamedNodeMap", writable: false, enumerable: false });

    this.getNamedItem = function(name) {
        return this[name];
    }
    
    this.setNamedItem = function(arg) {
        if (this.readonly) {// XXX - readonly doesn't exist yet
            throw new DOMException(NO_MODIFICATION_ALLOWED_ERR);
            return null;
        }
        if (this.length == 0 && !this.ownerDocument) {
            // initialize our document if we are inserting the first item
            // and not document has been set yet
            this.ownerDocument = arg.ownerDocument;
        } else if (arg.ownerDocument.uid != this.ownerDocument.uid) {
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

/**
 * DocumentFragment
 * @constructor
 * @class DocumentFragment is a "lightweight" or "minimal" Document object.
 * It is very common to want to be able to extract a portion of a document's
 * tree or to create a new fragment of a document. Imagine implementing a user
 * command like cut or rearranging a document by moving fragments around.
 * It is desirable to have an object which can hold such fragments and it is 
 * quite natural to use a Node for this purpose. While it is true that a 
 * Document object could fulfill this role, a Document object can potentially 
 * be a heavyweight object, depending on the underlying implementation.
 * What is really needed for this is a very lightweight object. DocumentFragment
 * is such an object.
 *
 * Furthermore, various operations -- such as inserting nodes as children of another
 * Node -- may take DocumentFragment objects as arguments; this results in all 
 * the child nodes of the DocumentFragment being moved to the child list of this node.
 *
 * @base Node
 */
function DocumentFragment() {
    /**
     * @private
     */
    Object.defineProperty(this, "__className__", { value: "DocumentFragment", writable: false, enumerable: false });
    
}
DocumentFragment.inherits(Node);

/**
 * DocumentFragment
 * @constructor
 * @class The Attr interface represents an attribute in an Element object.
 * Typically the allowable values for the attribute are defined in a schema 
 * associated with the document.
 * <br/>
 * Attr objects inherit the Node interface, but since they are not actually
 * child nodes of the element they describe, the DOM does not consider
 * them part of the document tree.<br/>Thus, the Node attributes parentNode,
 * previousSibling, and nextSibling have a null value for Attr objects.<br</
 * The DOM takes the view that attributes are properties of elements rather
 * than having a separate identity from the elements they are associated with;<br/>
 * this should make it more efficient to implement such features as default
 * attributes associated with all elements of a given type.<br/> Furthermore, 
 * Attr nodes may not be immediate children of a DocumentFragment.<br/> However,
 * they can be associated with Element nodes contained within a DocumentFragment.<br/>
 * In short, users and implementors of the DOM need to be aware that Attr nodes have
 * some things in common with other objects inheriting the Node interface,
 * but they also are quite distinct.
 * <br/><br/>
 * The attribute's effective value is determined as follows: if this attribute has been
 * explicitly assigned any value, that value is the attribute's effective value; otherwise,
 * if there is a declaration for this attribute, and that declaration includes a default value,
 * then that default value is the attribute's effective value; otherwise, the attribute does not
 * exist on this element in the structure model until it has been explicitly added.<br/>
 * Note that the Node.nodeValue attribute on the Attr instance can also be used to retrieve the
 * string version of the attribute's value(s).
 * <br/><br/>
 * If the attribute was not explicitly given a value in the instance document but has a default
 * value provided by the schema associated with the document, an attribute node will be created
 * with specified set to false. Removing attribute nodes for which a default value is defined in
 * the schema generates a new attribute node with the default value and specified set to false.<br/>
 * If validation occurred while invoking Document.normalizeDocument(), attribute nodes with specified
 * equals to false are recomputed according to the default attribute values provided by the schema.<br/>
 * If no default value is associate with this attribute in the schema, the attribute node is discarded.
 * <br/><br/>
 * In XML, where the value of an attribute can contain entity references, the child nodes of the Attr 
 * node may be either Text or EntityReference nodes (when these are in use; see the description of 
 * EntityReference for discussion).
 * <br/><br/>
 * The DOM Core represents all attribute values as simple strings, even if the DTD or schema associated
 * with the document declares them of some specific type such as tokenized.
 * @base Node
 */
function Attr() {
    /**
     * @private
     */
    Object.defineProperty(this, "__className__", { value: "Attr", writable: false, enumerable: false });
}
Attr.inherits(Attribute);

function CharacterData() {
    /**
     * @private
     */
    Object.defineProperty(this, "__className__", { value: "CharacterData", writable: false, enumerable: false });
}
CharacterData.inherits(CDATA);

/**
 * @private
 */
Object.defineProperty(Entity, "__className__", { value: "Entity", writable: false, enumerable: false });

/* Properties */
Object.defineProperty(Entity, "inputEncoding", { value: null, writable: false, enumerable: true });
Object.defineProperty(Entity, "notationName", { value: this.name, writable: false, enumerable: true });


function EntityReference(entity) {
    /**
     * @private
     */
    Object.defineProperty(this, "__className__", { value: "EntityReference", writable: false, enumerable: false });
    Object.defineProperty(this, "entity", { value: entity, writable: false, enumerable: false });
}
EntityReference.inherits(Node);

// XXX - fake objects to let jquery.js load smoothly (does all this make sense?)
function Window() {
}
window = new Window(); // XXX

function Navigator() {
    Object.defineProperty(this, "userAgent", { value: "JMX", writable: false, enumerable: false });
}
navigator = new Navigator(); // XXX

location = new Object();
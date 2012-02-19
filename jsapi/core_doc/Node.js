/**
 * @fileoverview
 * Node
 */

/**
 * Color is a wrapper class to JMXColor objects (used within the JMX engine)
 * @constructor
 * @class Wraps a JMXColor object and makes it available to javascript
 */
function Node(name)
{ 
    /**
     * The node name
     * @type string
     */
    this.name = name;
   
    /**
     * The node type
     * @type string
     */
    this.nodeType = "aType";

    /**
     * The parent node
     * @type Node
     */
    this.parentNode = aNode;

    /**
     * Array of child nodes
     * @type Array
     */
    this.childNodes = anArray;

    /**
     * The first child node (if any)
     * @type Node
     */
    this.firstChild = aChild;

    /**
     * The last child node (if any)
     * @type Node
     */
    this.lastChild = aChild;

    /**
     * The previous sibling node (if any)
     * @type Node
     */
    this.previousSibling = aSibling;

    /**
     * The next sibling node (if any)
     * @type Node
     */
    this.nextSibling = aSibling;

    /**
     * attributes
     * @type NodeMap
     */
    this.attributes = attibutes;

    /**
     * The namespace URI
     * @type string
     */
    this.namespaceURI = anUri;

    /**
     * The local node name (may differ from the name)
     * @type string
     */
    this.localName = aName;

    /**
     * The document owning this node
     * @type Document
     */
    this.ownerDocument = aDocument;

    /**
     * The node prefix
     * @type string
     */
    this.prefix = aPrefix;

    /**
     * The base node URI
     * @type string
     */
    this.baseURI = anURI;

    /**
     * The text content (if any)
     * @type string
     */
    this.textContext = "SomeText";

    /**
     * Insert this node before aNode
     * @param {Node} aNode
     */
    this.insertBefore = function(aNode) {
        // ...
    }

    /**
     * Replace oldChild with newChild
     * @param {Node} oldChild
     * @param {Node} newChild
     */
    this.replaceChild = function(newChild, oldChild) {
        // ...
    }

    /**
     * Remove aChild
     * @param {Node} aChild
     */
    this.removeChild = function(aChild) {
        // ...
    }

    /**
     * Append aChild to the children list
     * @param {Node} aChild
     */
    this.appendChild = function(aChild) {
        // ...
    }

    /**
     * Check if we have any child node
     * @returns true if we have child nodes false otherwise
     */
    this.hasChildNodes = function() {
        // ...
    }

    /**
     * Puts all Text nodes in the full depth of the sub-tree underneath this Node, including attribute nodes,
     * into a "normal" form where only structure (e.g., elements, comments, processing instructions, CDATA sections, and entity references)
     * separates Text nodes, i.e., there are neither adjacent Text nodes nor empty Text nodes.
     * This can be used to ensure that the DOM view of a document is the same as if it were saved and re-loaded, and is useful when operations
     * (such as XPointer [XPointer] lookups) that depend on a particular document tree structure are to be used.
     * If the parameter "normalize-characters" of the DOMConfiguration object attached to the Node.ownerDocument is true,
     * this method will also fully normalize the characters of the Text nodes.
     * Note: In cases where the document contains CDATASections, the normalize operation alone may not be sufficient,
     * since XPointers do not differentiate between Text nodes and CDATASection nodes.
     */
    this.normalize = function() {
        // ...
    }

    /**
     * Tests whether the DOM implementation implements a specific feature and that feature is supported by this node, as specified in DOM Features.
     * @param {DOMString} feature
     * @param {DOMString} version
     */
    this.isSupported = function(feature, version) {
        // ...
    }

    /**
     * Returns whether this node is the same node as the given one.
     * This method provides a way to determine whether two Node references returned by the implementation reference the same object.
     * When two Node references are references to the same object, even if through a proxy, the references may be used completely interchangeably,
     * such that all attributes have the same values and calling the same DOM method on either reference always has exactly the same effect.
     * @param {Node} aNode
     * @returns true if the two nodes are exactly the same node
     */
    this.isSameNode = function(aNode) {
        // ...
    }

    /**
     * Tests whether two nodes are equal.
     * This method tests for equality of nodes, not sameness (i.e., whether the two nodes are references to the same object)
     * which can be tested with Node.isSameNode(). All nodes that are the same will also be equal, though the reverse may not be true.
     * Two nodes are equal if and only if the following conditions are satisfied:
     * The two nodes are of the same type.
     * The following string attributes are equal: nodeName, localName, namespaceURI, prefix, nodeValue.
     * This is: they are both null, or they have the same length and are character for character identical.
     * The attributes NamedNodeMaps are equal. This is: they are both null, or they have the same length and for each node
     * that exists in one map there is a node that exists in the other map and is equal, although not necessarily at the same index.
     * The childNodes NodeLists are equal. This is: they are both null, or they have the same length and contain equal nodes at the same index.
     * Note that normalization can affect equality; to avoid this, nodes should be normalized before being compared.
     * For two DocumentType nodes to be equal, the following conditions must also be satisfied:
     * The following string attributes are equal: publicId, systemId, internalSubset.
     * The entities NamedNodeMaps are equal.
     * The notations NamedNodeMaps are equal.
     *
     * On the other hand, the following do not affect equality: the ownerDocument, baseURI, and parentNode attributes,
     * the specified attribute for Attr nodes, the schemaTypeInfo attribute for Attr and Element nodes, 
     * the Text.isElementContentWhitespace attribute for Text nodes, as well as any user data or event listeners registered on the nodes.
     * Note: As a general rule, anything not mentioned in the description above is not significant in consideration of equality checking.
     * Note that future versions of this specification may take into account more attributes and implementations conform to this specification
     * are expected to be updated accordingly.
     * @param {Node} aNode
     * @returns true if equals, false otherwise
     */
    this.isEqualNode = function(aNode) {
        // ...
    }

    /**
     * Associate an object to a key on this node. The object can later be retrieved from this node by calling getUserData with the same key.
     * @param {DOMString} key
     * @param {DOMUserData} data
     * @param {UserDataHandler} handler
     * @returns {DOMUserData}
     */
    this.setUserData = function(aKey, data, handler) {
        // ...
    }

    /**
     * Retrieves the object associated to a key on a this node. The object must first have been set to this node by calling setUserData with the same key.
     * @param {DOMString} key
     */
    this.getUserData = function(aKey) {
        // ...
    }

    /**
     * This method returns a specialized object which implements the specialized APIs of the specified feature and version, as specified in DOM Features.
     * The specialized object may also be obtained by using binding-specific casting methods but is not necessarily expected to, as discussed in Mixed DOM Implementations.
     * This method also allow the implementation to provide specialized objects which do not support the DOMImplementation interface.
     * @param {DOMString} feature
     * @param {DOMString} version
     */
    this.getFeature = function(feature, version) {
        // ...
    }

    /**
     * Look up the prefix associated to the given namespace URI, starting from this node. The default namespace declarations are ignored by this method.
     * See Namespace Prefix Lookup for details on the algorithm used by this method.
     * @param {DOMString} namespaceURI
     */
    this.lookupPrefix = function(namespaceURI) {
        // ...
    }

    /**
     * Returns a NodeList of all the Elements in document order with a given tag name and are contained in the document.
     * @param {DOMString} tagName
     */
    this.getElementsByTagName = function(tagName) {
        // ...
    }

    /**
     * Retrieves an attribute value by name.
     * @param {DOMString} name
     * @returns {DOMString}
     */
    this.getAttribute = function(name) {
        // ...
    }

    /**
     * Adds a new attribute. If an attribute with that name is already present in the element, its value is changed to be that of the value parameter.
     * This value is a simple string; it is not parsed as it is being set.
     * So any markup (such as syntax to be recognized as an entity reference) is treated as literal text, and needs to be appropriately escaped
     * by the implementation when it is written out. In order to assign an attribute value that contains entity references,
     * the user must create an Attr node plus any Text and EntityReference nodes, build the appropriate subtree, and use setAttributeNode 
     * to assign it as the value of an attribute.
     * To set an attribute with a qualified name and namespace URI, use the setAttributeNS method.
     * @param {DOMString} name
     * @param {DOMString} value
     */
     this.setAttribute = function(name, value) {
         // ...
     }

    /**
     * This method allows the registration of event listeners on the event target.
     * If an EventListener is added to an EventTarget while it is processing an event, it will not be triggered by the current actions
     * but may be triggered during a later stage of event flow, such as the bubbling phase.
     * If multiple identical EventListeners are registered on the same EventTarget with the same parameters the duplicate instances are discarded.
     * They do not cause the EventListener to be called twice and since they are discarded they do not need to be removed with the removeEventListener method.
     * @param {DOMString} type The event type for which the user is registering
     * @param {EventListener} listener The listener parameter takes an interface implemented by the user which contains the methods to be called when the event occurs.
     * @param {boolean} useCapture If true, useCapture indicates that the user wishes to initiate capture.
     * After initiating capture, all events of the specified type will be dispatched to the registered EventListener before being dispatched
     * to any EventTargets beneath them in the tree. Events which are bubbling upward through the tree will not trigger an EventListener designated to use capture.
     */
    this.addEventListener = function(type, listener, useCapture) {
        // ...
    }

    /**
     * This method allows the removal of event listeners from the event target.
     * If an EventListener is removed from an EventTarget while it is processing an event, it will not be triggered by the current actions.
     * EventListeners can never be invoked after being removed.
     * Calling removeEventListener with arguments which do not identify any currently registered EventListener on the EventTarget has no effect.
     * @param {DOMString} type Specifies the event type of the EventListener being removed.
     * @param {EventListener} listener The EventListener parameter indicates the EventListener to be removed.
     * @param {bookean} useCapture Specifies whether the EventListener being removed was registered as a capturing listener or not. If a listener was registered twice, one with capture and one without, each must be removed separately. Removal of a capturing listener does not affect a non-capturing version of the same listener, and vice versa.
     */
    this.removeEventListener = function(listener) {
        // ...
    }

    /**
     * This method allows the dispatch of events into the implementations event model.
     * Events dispatched in this manner will have the same capturing and bubbling behavior as events dispatched directly by the implementation.
     * The target of the event is the EventTarget on which dispatchEvent is called.
     * @param {Event} evt
     * Specifies the event type, behavior, and contextual information to be used in processing the event.
     */
    this.dispatchEvent = function(evt) {
        // ...
    }
    /**
     * isDefaultNamespace
     */
    this.isDefaultNamespace = function() {
    }

    /**
     * lookupNamespaceURI
     */
    this.lookupNamespaceURI = function() {
    }

    /**
     * compareDocumentPosition
     **/
    this.compareDocumentPosition = function() {
    }
}

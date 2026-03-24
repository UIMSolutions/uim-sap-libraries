/// OData $metadata document parser.
///
/// Parses SAP OData service metadata (EDMX/XML) to extract
/// entity types, entity sets, properties, navigation properties,
/// associations, and function imports.
module sap.odata.metadata;

import std.algorithm : canFind, startsWith, endsWith;
import std.array : appender, split;
import std.string : strip, indexOf, toLower;
import std.conv : to;
import std.exception : enforce;

/// Represents an EDM property.
struct EdmProperty
{
    string name;
    string type;         // e.g. "Edm.String", "Edm.Int32"
    bool nullable = true;
    int maxLength = -1;
    bool isKey;
    string label;        // sap:label
    bool creatable;      // sap:creatable
    bool updatable;      // sap:updatable
    bool sortable;       // sap:sortable
    bool filterable;     // sap:filterable
}

/// Represents an EDM navigation property.
struct EdmNavigationProperty
{
    string name;
    string relationship;
    string fromRole;
    string toRole;
    string targetEntityType;  // resolved
    string multiplicity;      // "1", "*", "0..1"
}

/// Represents an EDM entity type.
struct EdmEntityType
{
    string name;
    string namespace;
    string[] keyProperties;
    EdmProperty[] properties;
    EdmNavigationProperty[] navigationProperties;
    string label;        // sap:label
    string contentType;  // sap:content-version

    /// Full qualified name.
    string fullName() const
    {
        return namespace.length > 0 ? namespace ~ "." ~ name : name;
    }

    /// Find a property by name.
    const(EdmProperty)* findProperty(string propName) const
    {
        foreach (ref p; properties)
            if (p.name == propName)
                return &p;
        return null;
    }
}

/// Represents an entity set.
struct EdmEntitySet
{
    string name;
    string entityTypeName; // full qualified
    string label;          // sap:label
    bool creatable;
    bool updatable;
    bool deletable;
    bool pageable;
    bool addressable;
}

/// Represents a function import.
struct EdmFunctionImport
{
    string name;
    string httpMethod;   // "GET", "POST"
    string returnType;
    string entitySet;

    struct Parameter
    {
        string name;
        string type;
        string mode; // "In", "Out", "InOut"
        bool nullable;
    }

    Parameter[] parameters;
}

/// Represents an association.
struct EdmAssociation
{
    string name;
    string namespace;

    struct End
    {
        string type;
        string multiplicity;
        string role;
    }

    End[2] ends;
}

/// Parsed metadata document.
struct ServiceMetadata
{
    EdmEntityType[] entityTypes;
    EdmEntitySet[] entitySets;
    EdmFunctionImport[] functionImports;
    EdmAssociation[] associations;
    string defaultNamespace;

    /// Find entity type by name (simple or full qualified).
    const(EdmEntityType)* findEntityType(string name) const
    {
        foreach (ref et; entityTypes)
        {
            if (et.name == name || et.fullName() == name)
                return &et;
        }
        return null;
    }

    /// Find entity set by name.
    const(EdmEntitySet)* findEntitySet(string name) const
    {
        foreach (ref es; entitySets)
            if (es.name == name)
                return &es;
        return null;
    }

    /// Find the entity type for an entity set.
    const(EdmEntityType)* entityTypeForSet(string entitySetName) const
    {
        auto es = findEntitySet(entitySetName);
        if (es is null) return null;
        return findEntityType(es.entityTypeName);
    }

    /// Find function import by name.
    const(EdmFunctionImport)* findFunctionImport(string name) const
    {
        foreach (ref fi; functionImports)
            if (fi.name == name)
                return &fi;
        return null;
    }
}

/// Parse SAP OData $metadata XML response into ServiceMetadata.
///
/// This is a lightweight SAX-style parser that handles the common
/// SAP OData metadata patterns without requiring a full XML library.
ServiceMetadata parseMetadata(string xmlContent)
{
    ServiceMetadata meta;

    // Simple tag-based extraction approach.
    auto content = xmlContent;

    // Extract namespace from Schema element.
    meta.defaultNamespace = extractAttribute(content, "Schema", "Namespace");

    // Parse EntityTypes.
    foreach (etBlock; extractBlocks(content, "EntityType"))
    {
        EdmEntityType et;
        et.namespace = meta.defaultNamespace;
        et.name = extractAttr(etBlock, "Name");
        et.label = extractAttr(etBlock, "sap:label");

        // Key properties.
        foreach (keyBlock; extractBlocks(etBlock, "Key"))
        {
            foreach (propRef; extractSelfClosingTags(keyBlock, "PropertyRef"))
            {
                auto keyName = extractAttr(propRef, "Name");
                if (keyName.length > 0)
                    et.keyProperties ~= keyName;
            }
        }

        // Properties.
        foreach (propTag; extractSelfClosingTags(etBlock, "Property"))
        {
            EdmProperty prop;
            prop.name = extractAttr(propTag, "Name");
            prop.type = extractAttr(propTag, "Type");
            prop.nullable = extractAttr(propTag, "Nullable") != "false";
            auto ml = extractAttr(propTag, "MaxLength");
            if (ml.length > 0)
            {
                try prop.maxLength = ml.to!int;
                catch (Exception) {}
            }
            prop.label = extractAttr(propTag, "sap:label");
            prop.creatable = extractAttr(propTag, "sap:creatable") != "false";
            prop.updatable = extractAttr(propTag, "sap:updatable") != "false";
            prop.sortable = extractAttr(propTag, "sap:sortable") != "false";
            prop.filterable = extractAttr(propTag, "sap:filterable") != "false";
            prop.isKey = et.keyProperties.canFind(prop.name);
            et.properties ~= prop;
        }

        // Navigation properties.
        foreach (navTag; extractSelfClosingTags(etBlock, "NavigationProperty"))
        {
            EdmNavigationProperty nav;
            nav.name = extractAttr(navTag, "Name");
            nav.relationship = extractAttr(navTag, "Relationship");
            nav.fromRole = extractAttr(navTag, "FromRole");
            nav.toRole = extractAttr(navTag, "ToRole");
            et.navigationProperties ~= nav;
        }

        meta.entityTypes ~= et;
    }

    // Parse EntitySets.
    foreach (esTag; extractSelfClosingTags(content, "EntitySet"))
    {
        EdmEntitySet es;
        es.name = extractAttr(esTag, "Name");
        es.entityTypeName = extractAttr(esTag, "EntityType");
        es.label = extractAttr(esTag, "sap:label");
        es.creatable = extractAttr(esTag, "sap:creatable") != "false";
        es.updatable = extractAttr(esTag, "sap:updatable") != "false";
        es.deletable = extractAttr(esTag, "sap:deletable") != "false";
        es.pageable = extractAttr(esTag, "sap:pageable") != "false";
        es.addressable = extractAttr(esTag, "sap:addressable") != "false";
        meta.entitySets ~= es;
    }

    // Parse Associations.
    foreach (assocBlock; extractBlocks(content, "Association"))
    {
        EdmAssociation assoc;
        assoc.name = extractAttr(assocBlock, "Name");
        assoc.namespace = meta.defaultNamespace;

        auto ends = extractSelfClosingTags(assocBlock, "End");
        for (int i = 0; i < ends.length && i < 2; i++)
        {
            assoc.ends[i].type = extractAttr(ends[i], "Type");
            assoc.ends[i].multiplicity = extractAttr(ends[i], "Multiplicity");
            assoc.ends[i].role = extractAttr(ends[i], "Role");
        }

        meta.associations ~= assoc;
    }

    // Parse FunctionImports.
    foreach (fiTag; extractBlocks(content, "FunctionImport"))
    {
        EdmFunctionImport fi;
        fi.name = extractAttr(fiTag, "Name");
        fi.httpMethod = extractAttr(fiTag, "m:HttpMethod");
        if (fi.httpMethod.length == 0)
            fi.httpMethod = extractAttr(fiTag, "HttpMethod");
        fi.returnType = extractAttr(fiTag, "ReturnType");
        fi.entitySet = extractAttr(fiTag, "EntitySet");

        foreach (paramTag; extractSelfClosingTags(fiTag, "Parameter"))
        {
            EdmFunctionImport.Parameter p;
            p.name = extractAttr(paramTag, "Name");
            p.type = extractAttr(paramTag, "Type");
            p.mode = extractAttr(paramTag, "Mode");
            p.nullable = extractAttr(paramTag, "Nullable") != "false";
            fi.parameters ~= p;
        }

        meta.functionImports ~= fi;
    }

    return meta;
}

// --- Simple XML helpers (no external XML dependency) ---

private string extractAttribute(string xml, string elementName, string attrName)
{
    auto elemIdx = xml.indexOf("<" ~ elementName);
    if (elemIdx < 0) return "";
    auto rest = xml[elemIdx .. $];
    return extractAttr(rest, attrName);
}

private string extractAttr(string tag, string attrName)
{
    auto searchStr = attrName ~ "=\"";
    auto idx = tag.indexOf(searchStr);
    if (idx < 0) return "";
    auto start = idx + searchStr.length;
    auto endIdx = tag.indexOf("\"", start);
    if (endIdx < 0) return "";
    return tag[start .. endIdx];
}

private string[] extractBlocks(string xml, string tagName)
{
    string[] blocks;
    string remaining = xml;
    string openTag = "<" ~ tagName;
    string closeTag = "</" ~ tagName ~ ">";

    while (remaining.length > 0)
    {
        auto startIdx = remaining.indexOf(openTag);
        if (startIdx < 0) break;

        // Make sure it's a proper tag start (followed by space, > or /).
        auto afterTag = startIdx + openTag.length;
        if (afterTag < remaining.length)
        {
            char c = remaining[afterTag];
            if (c != ' ' && c != '>' && c != '/' && c != '\r' && c != '\n')
            {
                remaining = remaining[afterTag .. $];
                continue;
            }
        }

        auto endIdx = remaining.indexOf(closeTag, startIdx);
        if (endIdx < 0)
        {
            // Self-closing block — find the next >.
            auto closeAngle = remaining.indexOf(">", startIdx);
            if (closeAngle >= 0)
            {
                blocks ~= remaining[startIdx .. closeAngle + 1];
                remaining = remaining[closeAngle + 1 .. $];
            }
            else
            {
                break;
            }
            continue;
        }

        blocks ~= remaining[startIdx .. endIdx + closeTag.length];
        remaining = remaining[endIdx + closeTag.length .. $];
    }

    return blocks;
}

private string[] extractSelfClosingTags(string xml, string tagName)
{
    string[] tags;
    string remaining = xml;
    string openTag = "<" ~ tagName;

    while (remaining.length > 0)
    {
        auto startIdx = remaining.indexOf(openTag);
        if (startIdx < 0) break;

        auto afterTag = startIdx + openTag.length;
        if (afterTag < remaining.length)
        {
            char c = remaining[afterTag];
            if (c != ' ' && c != '>' && c != '/')
            {
                remaining = remaining[afterTag .. $];
                continue;
            }
        }

        // Find closing > (could be self-closing /> or >).
        auto closeAngle = remaining.indexOf(">", startIdx);
        if (closeAngle < 0) break;

        tags ~= remaining[startIdx .. closeAngle + 1];
        remaining = remaining[closeAngle + 1 .. $];
    }

    return tags;
}

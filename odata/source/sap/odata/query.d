/// OData query builder with fluent API.
///
/// Supports $filter, $select, $expand, $orderby, $top, $skip,
/// $inlinecount, $format, and custom query parameters.
module sap.odata.query;

import std.array : appender, join;
import std.conv : to;
import std.uri : encodeComponent;

/// Fluent OData query builder.
struct ODataQuery
{
    private string _entitySet;
    private string _entityKey;
    private string _navigationProperty;
    private string[] _select;
    private string[] _expand;
    private string[] _filters;
    private string[] _orderby;
    private long _top = -1;
    private long _skip = -1;
    private bool _inlineCount;
    private string _format;
    private string _search;
    private string[string] _customParams;

    /// Start building a query for an entity set.
    static ODataQuery entitySet(string name)
    {
        ODataQuery q;
        q._entitySet = name;
        return q;
    }

    /// Set entity key for single-entity access.
    /// Example: key("'12345'") → EntitySet('12345')
    ODataQuery key(string k)
    {
        _entityKey = k;
        return this;
    }

    /// Set composite key.
    /// Example: keys(["CompanyCode": "'1000'", "FiscalYear": "'2024'"])
    ODataQuery keys(string[string] keyParts)
    {
        auto buf = appender!string;
        bool first = true;
        foreach (k, v; keyParts)
        {
            if (!first) buf.put(",");
            buf.put(k);
            buf.put("=");
            buf.put(v);
            first = false;
        }
        _entityKey = buf.data;
        return this;
    }

    /// Navigate to a related entity set.
    ODataQuery navigate(string navProp)
    {
        _navigationProperty = navProp;
        return this;
    }

    /// Add fields to $select.
    ODataQuery select(string[] fields...)
    {
        _select ~= fields;
        return this;
    }

    /// Add paths to $expand.
    ODataQuery expand(string[] paths...)
    {
        _expand ~= paths;
        return this;
    }

    /// Add a raw $filter expression.
    ODataQuery filter(string expr)
    {
        _filters ~= expr;
        return this;
    }

    /// Add an equality filter: Field eq 'Value'.
    ODataQuery filterEq(string field, string value)
    {
        _filters ~= field ~ " eq '" ~ value ~ "'";
        return this;
    }

    /// Add a numeric equality filter: Field eq 123.
    ODataQuery filterEqNum(string field, long value)
    {
        _filters ~= field ~ " eq " ~ value.to!string;
        return this;
    }

    /// Add a "contains" filter (substringof for OData v2).
    ODataQuery filterContains(string field, string value)
    {
        _filters ~= "substringof('" ~ value ~ "'," ~ field ~ ")";
        return this;
    }

    /// Add a "starts with" filter.
    ODataQuery filterStartsWith(string field, string value)
    {
        _filters ~= "startswith(" ~ field ~ ",'" ~ value ~ "')";
        return this;
    }

    /// Add a greater-than filter.
    ODataQuery filterGt(string field, string value)
    {
        _filters ~= field ~ " gt '" ~ value ~ "'";
        return this;
    }

    /// Add a less-than filter.
    ODataQuery filterLt(string field, string value)
    {
        _filters ~= field ~ " lt '" ~ value ~ "'";
        return this;
    }

    /// Add a datetime filter (for SAP Edm.DateTime).
    ODataQuery filterDateTime(string field, string op, string datetimeValue)
    {
        _filters ~= field ~ " " ~ op ~ " datetime'" ~ datetimeValue ~ "'";
        return this;
    }

    /// Add $orderby fields.
    ODataQuery orderBy(string field, bool descending = false)
    {
        _orderby ~= field ~ (descending ? " desc" : " asc");
        return this;
    }

    /// Set $top.
    ODataQuery top(long n)
    {
        _top = n;
        return this;
    }

    /// Set $skip.
    ODataQuery skip(long n)
    {
        _skip = n;
        return this;
    }

    /// Enable $inlinecount=allpages.
    ODataQuery withInlineCount()
    {
        _inlineCount = true;
        return this;
    }

    /// Set $format.
    ODataQuery format(string fmt)
    {
        _format = fmt;
        return this;
    }

    /// Set $search (OData v4).
    ODataQuery search(string term)
    {
        _search = term;
        return this;
    }

    /// Add a custom query parameter.
    ODataQuery param(string name, string value)
    {
        _customParams[name] = value;
        return this;
    }

    /// Build the relative URL path with query string.
    string build()
    {
        auto path = appender!string;

        // Entity set with optional key.
        path.put(_entitySet);
        if (_entityKey.length > 0)
        {
            path.put("(");
            path.put(_entityKey);
            path.put(")");
        }

        // Navigation property.
        if (_navigationProperty.length > 0)
        {
            path.put("/");
            path.put(_navigationProperty);
        }

        // Query parameters.
        auto qparams = appender!(string[]);

        if (_select.length > 0)
            qparams.put("$select=" ~ encodeComponent(_select.join(",")));

        if (_expand.length > 0)
            qparams.put("$expand=" ~ encodeComponent(_expand.join(",")));

        if (_filters.length > 0)
            qparams.put("$filter=" ~ encodeComponent(_filters.join(" and ")));

        if (_orderby.length > 0)
            qparams.put("$orderby=" ~ encodeComponent(_orderby.join(",")));

        if (_top >= 0)
            qparams.put("$top=" ~ _top.to!string);

        if (_skip >= 0)
            qparams.put("$skip=" ~ _skip.to!string);

        if (_inlineCount)
            qparams.put("$inlinecount=allpages");

        if (_format.length > 0)
            qparams.put("$format=" ~ encodeComponent(_format));

        if (_search.length > 0)
            qparams.put("$search=" ~ encodeComponent(_search));

        foreach (k, v; _customParams)
            qparams.put(encodeComponent(k) ~ "=" ~ encodeComponent(v));

        auto result = path.data;
        auto ps = qparams.data;
        if (ps.length > 0)
            result ~= "?" ~ ps.join("&");

        return result;
    }

    /// Get just the entity set name.
    string getEntitySet() const { return _entitySet; }

    /// Convenience: build $count URL.
    string buildCount()
    {
        return build() ~ "/$count";
    }

    /// Convenience: build $value URL (for media resources).
    string buildValue()
    {
        return build() ~ "/$value";
    }
}

section FulcrumConnector;

// ========== Helpers ==========

// Ensure the user only enters e.g. "https://api.fulcrumapp.com"
// and we internally call ".../api/v2/..."
NormalizeApiBase = (baseUrl as text) as text =>
    let
        trimmed = if Text.EndsWith(baseUrl, "/")
                  then Text.Start(baseUrl, Text.Length(baseUrl) - 1)
                  else baseUrl,
        apiBase = trimmed & "/api/v2/"
    in
        apiBase;

Table.ToNavigationTable = (
    table as table,
    keyColumns as list,
    nameColumn as text,
    dataColumn as text,
    itemKindColumn as text,
    itemNameColumn as text,
    isLeafColumn as text
) as table =>
    let
        tableType = Value.Type(table),
        newTableType = Type.AddTableKey(tableType, keyColumns, true) meta 
        [
            NavigationTable.NameColumn = nameColumn, 
            NavigationTable.DataColumn = dataColumn,
            NavigationTable.ItemKindColumn = itemKindColumn, 
            Preview.DelayColumn = itemNameColumn, 
            NavigationTable.IsLeafColumn = isLeafColumn
        ],
        navigationTable = Value.ReplaceType(table, newTableType)
    in
        navigationTable;

PaginatedApiQuery = (baseUrl as text, apiToken as text, sqlQuery as text, perPage as number) as list =>
    let
        apiBase = NormalizeApiBase(baseUrl),
        headers = [
            #"Content-Type" = "application/json",
            #"Accept" = "application/json",
            #"X-ApiToken" = apiToken
        ],

        getPage = (page as number) =>
            let
                body = Text.Format("{""format"": ""json"", ""q"":""#{0}""}", {sqlQuery}),
                response = Web.Contents(
                    apiBase,
                    [
                        RelativePath = "query",
                        Query = [ page = Text.From(page), per_page = Text.From(perPage) ],
                        Headers = headers,
                        Content = Text.ToBinary(body),
                        ManualStatusHandling = {400}
                    ]
                ),
                json = Json.Document(response),
                rows = if Record.HasFields(json, "rows") then json[rows] else {}
            in
                rows,

        allPages =
            List.Generate(
                () => [page = 1, data = getPage(1)],
                each List.Count([data]) > 0,
                each [ page = [page] + 1, data = getPage([page] + 1) ],
                each [data]
            )
    in
        List.Combine(allPages);

GetFulcrumTable = (baseUrl as text, tableName as text, apiToken as text, perPage as number) as table =>
    let
        tableQuery = Text.Format("SELECT * FROM \""#{0}\"" ORDER BY 1", {tableName}),
        rows = PaginatedApiQuery(baseUrl, apiToken, tableQuery, perPage)
    in
        Table.FromRecords(rows);

// ========== Main (implementation) ==========

FulcrumConnectorImpl = (baseUrl as text) as table =>
    let
        perPage = 10000,

        apiToken =
            try Extension.CurrentCredential()[Key]
            otherwise error Error.Record(
                "AuthenticationError",
                "Fulcrum API token is missing",
                "Please provide a valid Fulcrum API token in the connector credentials."
            ),

        // Validate early (before listing tables)
        _validated = ValidateCredential(baseUrl, apiToken),

        // List tables
        tablesList = PaginatedApiQuery(baseUrl, apiToken, "SELECT * FROM tables ORDER BY 1", perPage),

        // Base nav table
        navTable = Table.FromRecords(List.Transform(tablesList, each [name = _[name]])),

        // Add column with data function
        navWithFuncs = Table.AddColumn(
            navTable,
            "Data",
            each try GetFulcrumTable(baseUrl, [name], apiToken, perPage) otherwise #table({}, {}),
            type table
        ),

        // Metadata for navigation
        navTyped  = Table.AddColumn(navWithFuncs, "ItemKind", each "Table", type text),
        navNamed  = Table.AddColumn(navTyped,    "ItemName", each [name], type text),
        navIsLeaf = Table.AddColumn(navNamed,    "IsLeaf",   each true,   type logical),

        navigation = Table.ToNavigationTable(navIsLeaf, {"name"}, "name", "Data", "ItemKind", "ItemName", "IsLeaf")
    in
        navigation;


// ========== Export with parameter UI metadata ==========

[DataSource.Kind="FulcrumConnector", Publish="FulcrumConnector.Publish"]
shared FulcrumConnector.Contents =
    Value.ReplaceType(
        FulcrumConnectorImpl,
        type function (
            baseUrl as (type text meta [
                Documentation.FieldCaption = "Fulcrum Base URL",
                Documentation.FieldDescription = "Enter the base URL of your Fulcrum instance (e.g., https://api.fulcrumapp.com). Do not include /api/v2/ — the connector will add it for you.",
                Documentation.SampleValues = {"https://api.fulcrumapp.com"},
                DefaultValue = "https://api.fulcrumapp.com"

            ])
        ) as table
    );

// ========== Data Source Kind ==========

FulcrumConnector = [
    TestConnection = (dataSourcePath) => 
        let
            // dataSourcePath is a JSON string like: {"baseUrl":"https://api.fulcrumapp.com"}
            json = Json.Document(dataSourcePath),
            baseUrl = json[baseUrl]
        in
            { "FulcrumConnector.Contents", baseUrl },

    Authentication = [ Key = [] ],
    Label = "Fulcrum API Token"
];

ValidateCredential = (baseUrl as text, apiToken as text) as logical =>
    let
        apiBase = NormalizeApiBase(baseUrl),
        response =
            Web.Contents(
                apiBase,
                [
                    // Use something cheap and reliable. If /api/v2/forms.json is valid for you, keep it.
                    RelativePath = "forms.json",
                    Headers = [
                        #"X-ApiToken" = apiToken,
                        #"Accept" = "application/json"
                    ],
                    ManualStatusHandling = {400, 401, 403}
                ]
            ),

        // If we got a 401/403/400, Web.Contents doesn't automatically throw because of ManualStatusHandling.
        // So try to parse JSON and validate expected fields.
        json = try Json.Document(response) otherwise null,

        ok =
            json <> null and
            Value.Is(json, type record) and
            Record.HasFields(json, "forms")
    in
        if ok then
            true
        else
            error Error.Record(
                "AuthenticationError",
                "Fulcrum authentication failed",
                "Your API token was rejected or the server response wasn’t recognized. Verify the token and base URL, then try again."
            );


// ========== Publish / Icons ==========

FulcrumConnector.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { "Fulcrum", "Connect to Fulcrum" },
    LearnMoreUrl = "https://docs.fulcrumapp.com",
    SourceImage = FulcrumConnector.Icons,
    SourceTypeImage = FulcrumConnector.Icons
];

FulcrumConnector.Icons = [
    Icon16 = { Extension.Contents("FulcrumConnector16.png"), Extension.Contents("FulcrumConnector20.png"), Extension.Contents("FulcrumConnector24.png"), Extension.Contents("FulcrumConnector32.png") },
    Icon32 = { Extension.Contents("FulcrumConnector32.png"), Extension.Contents("FulcrumConnector40.png"), Extension.Contents("FulcrumConnector48.png"), Extension.Contents("FulcrumConnector64.png") }
];

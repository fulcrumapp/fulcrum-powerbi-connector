section FulcrumConnector;

[DataSource.Kind="FulcrumConnector", Publish="FulcrumConnector.Publish"]
shared FulcrumConnector.Contents = (optional dataSourcePath as nullable text) =>
    let
        perPage = 10000,
        apiToken = try Extension.CurrentCredential()[Key] otherwise error "API token is missing or invalid",

        // Query Fulcrum for available tables
        tablesList = PaginatedApiQuery(apiToken, "SELECT * FROM tables ORDER BY 1", perPage),

        // Build base table
        navTable = Table.FromRecords(List.Transform(tablesList, each [name = _[name]])),

        // Add column with data function
        navWithFuncs = Table.AddColumn(
            navTable,
            "Data",
            each 
                try GetFulcrumTable([name], apiToken, perPage) otherwise #table({}, {}),
            type table
        ),

        // Add metadata columns required by Table.ToNavigationTable
        navTyped = Table.AddColumn(navWithFuncs, "ItemKind", each "Table", type text),
        navNamed = Table.AddColumn(navTyped, "ItemName", each [name], type text),
        navIsLeaf = Table.AddColumn(navNamed, "IsLeaf", each true, type logical),

        // Final navigation table
        navigation = Table.ToNavigationTable(
            navIsLeaf,
            {"name"},
            "name",
            "Data",
            "ItemKind",
            "ItemName",
            "IsLeaf"
        )
    in
        navigation;


// Helper function to query a selected table
GetFulcrumTable = (tableName as text, apiToken as text, perPage as number) as table =>
    let
        tableQuery = Text.Format("SELECT * FROM \""#{0}\"" ORDER BY 1", {tableName}),
        rows = PaginatedApiQuery(apiToken, tableQuery, perPage),
        resultTable = Table.FromRecords(rows)
    in
        resultTable;

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

PaginatedApiQuery = (apiToken as text, sqlQuery as text, perPage as number) as list =>
    let
        baseUrl = "https://api.fulcrumapp.com/api/v2/query",
        
        headers = [
            #"Content-Type" = "application/json",
            #"Accept" = "application/json",
            #"X-ApiToken" = apiToken
        ],

        getPage = (page as number) =>
            let
                url = baseUrl & "?" & Uri.BuildQueryString([
                    page = Text.From(page),
                    per_page = Text.From(perPage)
                ]),
                body = Text.Format("{""format"": ""json"", ""q"":""#{0}""}", {sqlQuery}),
                response = Web.Contents(url, [
                    Headers = headers,
                    Content = Text.ToBinary(body),
                    ManualStatusHandling = {400}
                ]),
                json = Json.Document(response),
                rows = if Record.HasFields(json, "rows") then json[rows] else {}
            in
                rows,

        allPages = List.Generate(
            () => [page = 1, data = getPage(1)],
            each List.Count([data]) > 0,
            each [
                page = [page] + 1,
                data = getPage([page] + 1)
            ],
            each [data]
        ),
        combinedRows = List.Combine(allPages)
    in
        combinedRows;


// Used for validating API Key in TestConnection
FulcrumConnector = [
    TestConnection = (dataSourcePath as nullable text) as list =>
    let
        token = try Extension.CurrentCredential()[Key] otherwise error "API token missing or invalid",
        response = Web.Contents(
            "https://api.fulcrumapp.com/api/v2/forms.json",
            [
                Headers = [
                    #"X-ApiToken" = token,
                    #"Accept" = "application/json"
                ],
                ManualStatusHandling = {400, 401, 403}
            ]
        ),
        json = Json.Document(response),
        _ = if Record.HasFields(json, "forms") then true else error "Invalid API Key or response format."
    in
        { "FulcrumConnector.Contents", dataSourcePath },
    // Authentication (API Key)
    Authentication = [
        Key = []
    ],
    Label = "Fulcrum API Token"
];

// Metadata
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
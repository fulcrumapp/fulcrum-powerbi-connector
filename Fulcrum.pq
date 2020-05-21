// This file contains your Data Connector logic
[Version = "1.0.0"]

section Fulcrum;

[DataSource.Kind="Fulcrum", Publish="Fulcrum.Publish"]
shared Fulcrum.Query = (#"Fulcrum Query" as text) =>
    let
        apiKey = Extension.CurrentCredential()[Key],
        table = Func(#"Fulcrum Query", 1, {})
    in
        table;

Func = (query as text, page as number, optional previousResult) =>
    let 
        res = Json.Document(Web.Contents("https://api.fulcrumapp.com", 
         [RelativePath = "api/v2/query",
         Query = [token = Extension.CurrentCredential()[Key], q = query, format = "json", page = Number.ToText(page), per_page = Number.ToText(10000)],
         Headers=[Accept="application/json", #"Content-type"="application/json"]]
        )),
        rows = res[rows],
        result = if (List.IsEmpty(rows)) then
            Table.FromRecords(List.Combine({previousResult, rows}))
        else
            Func(query, page + 1, List.Combine({previousResult, rows}))
          
    in
        result;

// Data Source Kind description
Fulcrum = [
     TestConnection = (dataSourcePath) => {"Fulcrum.Query", dataSourcePath},
     Authentication = [
         Key = []
        // UsernamePassword = [],
        // Windows = [],
        //Implicit = []
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
Fulcrum.Publish = [
    Beta = true,
    Category = "Online Services",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://fulcrumapp.com/",
    SourceImage = Fulcrum.Icons,
    SourceTypeImage = Fulcrum.Icons
];

Fulcrum.Icons = [
    Icon16 = { Extension.Contents("Fulcrum16.png"), Extension.Contents("Fulcrum16.png"), Extension.Contents("Fulcrum16.png"), Extension.Contents("Fulcrum16.png") },
    Icon32 = { Extension.Contents("Fulcrum16.png"), Extension.Contents("Fulcrum16.png"), Extension.Contents("Fulcrum16.png"), Extension.Contents("Fulcrum16.png") }
];

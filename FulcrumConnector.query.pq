section FulcrumConnectorQuery;

// This is a test expression used by PQTest to validate the connector.
// It should reference exactly one shared data source function.

shared FulcrumConnectorQuery = FulcrumConnector.Contents(null);

# Fulcrum Power BI Connector

A custom Power BI connector (`.mez` file) that connects to the [Fulcrum](https://www.fulcrumapp.com/) API, allowing you to query and visualize your Fulcrum data directly in Power BI.

## Prerequisites

- **Power BI Desktop** and/or **Power BI Service**
- A **Fulcrum API key** — generate one from your Fulcrum account under **Settings > API**

## Installation

### 1. Copy the connector file

Place the `FulcrumConnector.mez` file into the custom connectors directory:

```
[Documents]\Power BI Desktop\Custom Connectors\
```

> If the `Custom Connectors` folder does not exist, create it manually.

### 2. Allow custom connectors to load

Power BI blocks uncertified connectors by default. You must lower the security setting to use this connector:

1. Open **Power BI Desktop**.
2. Navigate to **File > Options and settings > Options > Security**.
3. Under **Data Extensions**, select **(Not Recommended) Allow any extension to load without validation or warning**.
4. Click **OK** and **restart** Power BI Desktop.

## Connecting to Fulcrum

1. In Power BI Desktop, select **Home > Get Data**.
2. Search for **Fulcrum** in the connector list and select it.
3. When prompted, enter the **Base URL** for your Fulcrum instance.
   - For most users this is `https://api.fulcrumapp.com`. The connector appends `/api/v2/` automatically — do not include it yourself.
4. On the authentication page, select **Key** and enter your **Fulcrum API key**.
5. After authenticating, a navigation table will appear listing all of your Fulcrum forms. Select the tables you want to import and click **Load** (or **Transform Data** to shape the data first).

The connector automatically paginates through large result sets (10,000 rows per page), so all records are retrieved regardless of table size.


## Working with Choice Fields

Single choice, multiple choice, and classification fields are returned as `List` values in Power Query. To convert them into readable, comma-separated text:

1. In **Transform Data**, click the column header of the field showing `List`.
2. From the dropdown menu, select **Extract Values...**.
3. Choose **Comma** as the delimiter and click **OK**.

The column will now display a comma-separated string of the selected values. This is standard Power BI behavior and applies to any Fulcrum field that supports multiple selections.

## On-Premises Data Gateway (Power BI Service)

To use this connector with **Power BI Service** (Power BI Online) for scheduled refresh, you must set up the **On-Premises Data Gateway**:

### Gateway installation

1. Download and install the [On-Premises Data Gateway](https://learn.microsoft.com/en-us/data-integration/gateway/service-gateway-install) on a machine that has network access to the Fulcrum API.
2. Sign in with your Power BI account during setup.

### Enabling the custom connector on the gateway

1. Copy the `FulcrumConnector.mez` file to the gateway's custom connector directory. By default this is:
   ```
   [Documents]\Power BI Desktop\Custom Connectors\
   ```
   You can also configure a custom path in the gateway settings under **Connectors**.
2. Open the **On-Premises Data Gateway** application.
3. Navigate to the **Connectors** tab.
4. Confirm the path to the folder containing your `.mez` file and enable **Load custom data connectors from this folder**.
5. Restart the gateway service.

Note: The Power BI On-premises Data Gateway service account, typically NT Service\PBIEgwService, requires Log on as a service rights on the local machine and access to the folder where the connector is being stored.

### Configuring the data source in Power BI Service

1. In Power BI Service, go to **Settings > Manage connections and gateways**.
2. Select your gateway cluster and add a new data source.
3. Choose **Fulcrum** from the data source type list.
4. Enter the Base URL (`https://api.fulcrumapp.com`) and your API key.
5. Test the connection and save.

### Configuring the semantic model for gateway refresh

After publishing a report that uses the Fulcrum connector to **Power BI Service**, you must map the semantic model (dataset) to the gateway data source so the service can refresh the data through your gateway.

1. In **Power BI Service**, navigate to your **workspace** and locate the published semantic model.
2. Select **⋯ > Settings** for the semantic model (or go to **Settings > Semantic models** and select it there).
3. Expand **Gateway and cloud connections**.
4. Toggle **On-premises or VNet data gateway** to **On**. This allows the semantic model to send queries through your gateway instead of attempting a direct cloud connection.
5. Under **Gateway connections**, select the **gateway cluster** where the Fulcrum connector is installed.
6. In your **gateway cluster settings**, enable the option that allows the gateway to refresh **custom connectors**.
7. Create a **new connection** for the **Fulcrum Connector** through the selected gateway.
8. Map the **Fulcrum data source** to the gateway connection you created. Ensure the **data source name and credentials match** the connection configuration.
9. Click **Apply** to save the configuration.
10. (Optional) Expand **Refresh** and configure a **scheduled refresh** cadence to keep your Fulcrum data automatically up to date.

Once configured, published semantic models using this connector will refresh on schedule through the gateway.

## Troubleshooting

| Issue | Resolution |
|---|---|
| Connector does not appear in **Get Data** | Verify the `.mez` file is in the correct `Custom Connectors` folder and that the security setting has been changed. Restart Power BI Desktop. |
| Authentication fails | Double-check your API key. Ensure it has not been revoked in Fulcrum under **Settings > API**. |
| No tables returned | Confirm your API key has access to at least one form in your Fulcrum organization. |
| Gateway cannot load the connector | Ensure the `.mez` file is in the gateway's custom connector directory, that **Load custom data connectors** is enabled, and that the gateway service has been restarted. |

## Additional Resources

- [Fulcrum Power BI Connector Help Article](https://help.fulcrumapp.com/en/articles/3872014-connecting-to-power-bi)
- [Fulcrum API Documentation](https://docs.fulcrumapp.com/)
- [Power BI Custom Connectors](https://learn.microsoft.com/en-us/power-bi/connect-data/desktop-connector-extensibility)
- [On-Premises Data Gateway Documentation](https://learn.microsoft.com/en-us/data-integration/gateway/service-gateway-install)

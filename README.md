# fulcrum-powerbi-connector

To use Fulcrum's custom connector, put the connector .mez file in the [Documents]\Power BI Desktop\Custom Connectors folder. If the folder doesn't exist, create it.

Adjust the data extension security settings as follows:

In Power BI Desktop, select File > Options and settings > Options > Security.

Under Data Extensions, select (Not Recommended) Allow any extension to load without validation or warning. Select OK, and then restart Power BI Desktop.

This connector requires an API key from Fulcrum. After opening the connector from the get data window you will enter your sql query.  On the following page you will enter your API Key and the connector will fetch your data. 

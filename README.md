# Azure Function App - Data Unification

This Azure Function App unifies data from 4 different database types:
- SQL Server (Relational)
- Cosmos DB (Document NoSQL)
- Table Storage (Key-Value NoSQL)
- MongoDB (Document NoSQL)

## Features

### Triggers
1. **HTTP Trigger** (`/api/unify-data`): Returns unified data from all databases
2. **Storage Trigger**: Triggered when files are uploaded to blob storage
3. **Timer Trigger**: Scheduled to run every 30 minutes

### Database Connectivity
- **SQL Server**: Uses pyodbc for connection
- **Cosmos DB**: Uses azure-cosmos SDK
- **Table Storage**: Uses azure-data-tables SDK
- **MongoDB**: Uses pymongo driver

## Setup

### Prerequisites
- Python 3.8+
- Azure Functions Core Tools
- Azure CLI (for deployment)

### Local Development

1. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Configure connection strings**:
   Edit `local.settings.json` and replace placeholder values with your actual connection strings:
   ```json
   {
     "SQL_CONNECTION_STRING": "your_sql_connection_string",
     "COSMOS_CONNECTION_STRING": "your_cosmos_connection_string",
     "TABLE_STORAGE_CONNECTION_STRING": "your_table_storage_connection_string",
     "MONGODB_CONNECTION_STRING": "your_mongodb_connection_string",
     "STORAGE_CONNECTION_STRING": "your_storage_connection_string"
   }
   ```

3. **Run locally**:
   ```bash
   func start
   ```

### Deployment

1. **Package the function**:
   ```bash
   func azure functionapp publish <your-function-app-name>
   ```

2. **Configure app settings** in Azure Portal with the same connection strings

## API Endpoints

### HTTP Trigger
- **URL**: `/api/unify-data`
- **Method**: GET
- **Response**: JSON with unified data from all 4 databases

### Storage Trigger
- **Trigger**: Blob upload to `uploads/{name}`
- **Action**: Processes uploaded file and unifies with database data

### Timer Trigger
- **Schedule**: Every 30 minutes
- **Action**: Performs scheduled data unification

## Sample Data

The function creates sample data in each database if it doesn't exist:

- **SQL Server**: `customers` table with customer information
- **Cosmos DB**: `items` container with product catalog
- **Table Storage**: `employees` table with employee records
- **MongoDB**: `inventory` collection with inventory items

## Error Handling

- All database operations are wrapped in try-catch blocks
- Errors are logged and return error objects instead of failing
- Connection strings are validated at runtime

## Dependencies

- `azure-functions`: Core Azure Functions runtime
- `pyodbc`: SQL Server connectivity
- `azure-cosmos`: Cosmos DB SDK
- `azure-data-tables`: Table Storage SDK
- `pymongo`: MongoDB driver
- `requests`: HTTP requests (utility) 
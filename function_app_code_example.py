# pylint: disable=C0114,C0115,C0116
# Azure Function App Code Example
# This would be packaged as function_code.zip and deployed

import azure.functions as func
import json
import pyodbc  # pylint: disable=import-error
import os
from azure.cosmos import CosmosClient
from azure.data.tables import TableServiceClient
import pymongo
import logging
from datetime import datetime

app = func.FunctionApp()

# HTTP Trigger - Data Unification from All 4 Databases
@app.route(route="unify-data", auth_level=func.AuthLevel.ANONYMOUS)
def unify_data_http(req: func.HttpRequest) -> func.HttpResponse:  # pylint: disable=unused-argument
    logging.info('HTTP trigger function processed a request.')
    
    try:
        # Get data from all 4 databases
        sql_data = get_sql_data()
        cosmos_data = get_cosmos_data()
        table_data = get_table_storage_data()
        mongodb_data = get_mongodb_data()
        
        # Unify all data
        unified_data = {
            "timestamp": datetime.utcnow().isoformat(),
            "databases": {
                "sql_server": {
                    "type": "relational",
                    "data": sql_data,
                    "count": len(sql_data)
                },
                "cosmos_db": {
                    "type": "document_nosql",
                    "data": cosmos_data,
                    "count": len(cosmos_data)
                },
                "table_storage": {
                    "type": "key_value_nosql",
                    "data": table_data,
                    "count": len(table_data)
                },
                "mongodb": {
                    "type": "document_nosql",
                    "data": mongodb_data,
                    "count": len(mongodb_data)
                }
            },
            "total_unified_records": len(sql_data) + len(cosmos_data) + len(table_data) + len(mongodb_data),
            "source": "http_trigger"
        }
        
        return func.HttpResponse(
            json.dumps(unified_data, indent=2),
            status_code=200,
            mimetype="application/json"
        )
        
    except Exception as e:  # pylint: disable=broad-exception-caught
        logging.error("Error in HTTP trigger: %s", str(e))
        return func.HttpResponse(
            json.dumps({"error": str(e)}),
            status_code=500,
            mimetype="application/json"
        )

# Storage Trigger - Data Unification on File Upload
@app.blob_trigger(arg_name="myblob", 
                  path="uploads/{name}",
                  connection="STORAGE_CONNECTION_STRING")
def unify_data_storage(myblob: func.InputStream):
    logging.info("Storage trigger function processed blob: %s", myblob.name)
    
    try:
        # Read the uploaded file
        blob_content = myblob.read().decode('utf-8')
        
        # Get data from all databases
        sql_data = get_sql_data()
        cosmos_data = get_cosmos_data()
        table_data = get_table_storage_data()
        mongodb_data = get_mongodb_data()
        
        # Create unified data file
        unified_data = {
            "timestamp": datetime.utcnow().isoformat(),
            "trigger_file": myblob.name,
            "file_content_length": len(blob_content),
            "databases": {
                "sql_server": {"data": sql_data, "count": len(sql_data)},
                "cosmos_db": {"data": cosmos_data, "count": len(cosmos_data)},
                "table_storage": {"data": table_data, "count": len(table_data)},
                "mongodb": {"data": mongodb_data, "count": len(mongodb_data)}
            },
            "total_unified_records": len(sql_data) + len(cosmos_data) + len(table_data) + len(mongodb_data),
            "source": "storage_trigger"
        }
        
        # Save unified data to a JSON file (could be saved to another storage)
        logging.info("Unified data from 4 databases: %s total records", 
                    unified_data['total_unified_records'])
        
    except Exception as e:  # pylint: disable=broad-exception-caught
        logging.error("Error in storage trigger: %s", str(e))

def get_sql_data():
    """Get sample data from SQL Database"""
    try:
        conn_str = os.environ["SQL_CONNECTION_STRING"]
        conn = pyodbc.connect(conn_str)  # pylint: disable=no-member
        cursor = conn.cursor()
        
        # Create sample table and insert data if not exists
        cursor.execute("""
            IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='customers' AND xtype='U')
            CREATE TABLE customers (
                id INT IDENTITY(1,1) PRIMARY KEY,
                name NVARCHAR(100),
                email NVARCHAR(100),
                city NVARCHAR(50)
            )
        """)
        
        # Insert sample data
        cursor.execute("SELECT COUNT(*) FROM customers")
        count = cursor.fetchone()[0]
        
        if count == 0:
            sample_customers = [
                ('John Doe', 'john@example.com', 'New York'),
                ('Jane Smith', 'jane@example.com', 'Los Angeles'),
                ('Bob Johnson', 'bob@example.com', 'Chicago'),
                ('Alice Brown', 'alice@example.com', 'Houston')
            ]
            
            for customer in sample_customers:
                cursor.execute(
                    "INSERT INTO customers (name, email, city) VALUES (?, ?, ?)",
                    customer
                )
            conn.commit()
        
        # Get the data
        cursor.execute("SELECT id, name, email, city FROM customers")
        rows = cursor.fetchall()
        
        data = []
        for row in rows:
            data.append({
                "id": row[0],
                "name": row[1],
                "email": row[2],
                "city": row[3],
                "db_type": "sql_server"
            })
        
        conn.close()
        return data
        
    except Exception as e:
        logging.error("Error getting SQL data: %s", str(e))
        return [{"error": "Failed to fetch SQL data", "details": str(e)}]

def get_cosmos_data():
    """Get sample data from Cosmos DB"""
    try:
        conn_str = os.environ["COSMOS_CONNECTION_STRING"]
        client = CosmosClient.from_connection_string(conn_str)
        
        database = client.get_database_client("database2")
        container = database.get_container_client("items")
        
        # Insert sample data if container is empty
        try:
            items = list(container.query_items(
                query="SELECT VALUE COUNT(1) FROM c",
                enable_cross_partition_query=True
            ))
            
            if items[0] == 0:
                sample_items = [
                    {"id": "1", "product": "Laptop", "price": 999.99, "category": "Electronics"},
                    {"id": "2", "product": "Phone", "price": 599.99, "category": "Electronics"},
                    {"id": "3", "product": "Desk", "price": 299.99, "category": "Furniture"},
                    {"id": "4", "product": "Chair", "price": 199.99, "category": "Furniture"}
                ]
                
                for item in sample_items:
                    container.create_item(body=item)
        except (ValueError, KeyError, AttributeError) as e:  # pylint: disable=broad-exception-caught
            logging.warning("Could not insert sample data: %s", str(e))
        
        # Get the data
        items = list(container.query_items(
            query="SELECT * FROM c",
            enable_cross_partition_query=True
        ))
        
        data = []
        for item in items:
            data.append({
                "id": item.get("id"),
                "product": item.get("product"),
                "price": item.get("price"),
                "category": item.get("category"),
                "db_type": "cosmos_db"
            })
        
        return data
        
    except Exception as e:  # pylint: disable=broad-exception-caught
        logging.error("Error getting Cosmos data: %s", str(e))
        return [{"error": "Failed to fetch Cosmos data", "details": str(e)}]

def get_table_storage_data():
    """Get sample data from Table Storage"""
    try:
        conn_str = os.environ["TABLE_STORAGE_CONNECTION_STRING"]
        table_service = TableServiceClient.from_connection_string(conn_str=conn_str)
        
        # Get employees table
        table_client = table_service.get_table_client(table_name="employees")
        
        # Insert sample data if table is empty
        try:
            entities = list(table_client.list_entities())
            
            if len(entities) == 0:
                sample_employees = [
                    {
                        "PartitionKey": "HR",
                        "RowKey": "001",
                        "name": "Alice Johnson",
                        "department": "Human Resources",
                        "salary": 75000
                    },
                    {
                        "PartitionKey": "IT",
                        "RowKey": "002", 
                        "name": "Bob Wilson",
                        "department": "Information Technology",
                        "salary": 85000
                    },
                    {
                        "PartitionKey": "Sales",
                        "RowKey": "003",
                        "name": "Carol Davis",
                        "department": "Sales",
                        "salary": 65000
                    }
                ]
                
                for employee in sample_employees:
                    table_client.create_entity(entity=employee)
        except (ValueError, KeyError, AttributeError) as e:  # pylint: disable=broad-exception-caught
            logging.warning("Could not insert sample data: %s", str(e))
        
        # Get the data
        entities = list(table_client.list_entities())
        
        data = []
        for entity in entities:
            data.append({
                "partition_key": entity.get("PartitionKey"),
                "row_key": entity.get("RowKey"),
                "name": entity.get("name"),
                "department": entity.get("department"),
                "salary": entity.get("salary"),
                "db_type": "table_storage"
            })
        
        return data
        
    except Exception as e:  # pylint: disable=broad-exception-caught
        logging.error("Error getting Table Storage data: %s", str(e))
        return [{"error": "Failed to fetch Table Storage data", "details": str(e)}]

def get_mongodb_data():
    """Get sample data from MongoDB"""
    try:
        conn_str = os.environ["MONGODB_CONNECTION_STRING"]
        client = pymongo.MongoClient(conn_str)
        
        db = client["inventorydb"]
        collection = db["inventory"]
        
        # Insert sample data if collection is empty
        try:
            count = collection.count_documents({})
            
            if count == 0:
                sample_inventory = [
                    {
                        "_id": "inv001",
                        "item": "Widget A",
                        "quantity": 150,
                        "warehouse": "North",
                        "last_updated": "2024-01-15"
                    },
                    {
                        "_id": "inv002", 
                        "item": "Widget B",
                        "quantity": 75,
                        "warehouse": "South",
                        "last_updated": "2024-01-16"
                    },
                    {
                        "_id": "inv003",
                        "item": "Gadget X",
                        "quantity": 200,
                        "warehouse": "East",
                        "last_updated": "2024-01-17"
                    },
                    {
                        "_id": "inv004",
                        "item": "Gadget Y", 
                        "quantity": 50,
                        "warehouse": "West",
                        "last_updated": "2024-01-18"
                    }
                ]
                
                collection.insert_many(sample_inventory)
        except (pymongo.errors.PyMongoError, ValueError) as e:  # pylint: disable=broad-exception-caught
            logging.warning("Could not insert sample data: %s", str(e))
        
        # Get the data
        documents = list(collection.find({}))
        
        data = []
        for doc in documents:
            data.append({
                "id": doc.get("_id"),
                "item": doc.get("item"),
                "quantity": doc.get("quantity"),
                "warehouse": doc.get("warehouse"),
                "last_updated": doc.get("last_updated"),
                "db_type": "mongodb"
            })
        
        return data
        
    except Exception as e:  # pylint: disable=broad-exception-caught
        logging.error("Error getting MongoDB data: %s", str(e))
        return [{"error": "Failed to fetch MongoDB data", "details": str(e)}]

# Timer Trigger - Optional scheduled data unification from all databases
@app.schedule(schedule="0 */30 * * * *", arg_name="myTimer", run_on_startup=True)
def scheduled_unify(myTimer: func.TimerRequest) -> None:  # pylint: disable=unused-argument
    logging.info('Timer trigger function executed.')
    
    try:
        # Perform scheduled data unification from all 4 databases
        sql_data = get_sql_data()
        cosmos_data = get_cosmos_data()
        table_data = get_table_storage_data()
        mongodb_data = get_mongodb_data()
        
        unified_data = {
            "timestamp": datetime.utcnow().isoformat(),
            "sql_count": len(sql_data),
            "cosmos_count": len(cosmos_data),
            "table_storage_count": len(table_data),
            "mongodb_count": len(mongodb_data),
            "total_unified": len(sql_data) + len(cosmos_data) + len(table_data) + len(mongodb_data),
            "source": "timer_trigger"
        }
        
        logging.info("Scheduled unification completed: %s", unified_data)
        
    except Exception as e:  # pylint: disable=broad-exception-caught
        logging.error("Error in scheduled trigger: %s", str(e))
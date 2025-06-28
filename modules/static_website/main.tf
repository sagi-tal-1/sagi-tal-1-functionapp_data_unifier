# Storage account for static website
resource "azurerm_storage_account" "static_website" {
  name                     = var.storage_account.name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.storage_account.account_tier
  account_replication_type = var.storage_account.account_replication_type

  static_website {
    index_document     = var.storage_account.index_document
    error_404_document = var.storage_account.error_404_document
  }

  tags = var.tags
}

# Storage container for function app
resource "azurerm_storage_container" "function_releases" {
  name                  = "function-releases"
  storage_account_name  = azurerm_storage_account.static_website.name
  container_access_type = "private"
}

# Sample index.html file
resource "azurerm_storage_blob" "index" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.static_website.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source_content         = <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Static Website PoC</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        button { padding: 10px 20px; margin: 10px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Static Website PoC</h1>
        <p>This is a proof of concept for a static website with Azure Functions data unification.</p>
        
        <h2>Test Data Unification</h2>
        <button onclick="testHttpTrigger()">Test HTTP Trigger</button>
        <button onclick="uploadFile()">Upload File (Storage Trigger)</button>
        
        <div id="results"></div>
        
        <script>
            async function testHttpTrigger() {
                try {
                    const response = await fetch('/api/unify-data');
                    const data = await response.json();
                    document.getElementById('results').innerHTML = '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
                } catch (error) {
                    document.getElementById('results').innerHTML = 'Error: ' + error.message;
                }
            }
            
            function uploadFile() {
                const input = document.createElement('input');
                input.type = 'file';
                input.onchange = async (e) => {
                    const file = e.target.files[0];
                    if (file) {
                        // This would typically upload to a designated container
                        alert('File upload would trigger storage-based function');
                    }
                };
                input.click();
            }
        </script>
    </div>
</body>
</html>
EOF

  depends_on = [azurerm_storage_account.static_website]
}
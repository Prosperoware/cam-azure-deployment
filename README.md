# CAM Azure Stack Deployment Template


[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FProsperoware%2Fcam-azure-template%2Fmaster%2Fazuredeploy.json)

When you deploy this Azure Resource Manager template, the following entities will be created:
- Storage Account
-- Storage blob container to keep application configuration files
-- Encryption Scope
-- Storage BLOB container with the encryption scope to keep the data at rest
- Azure Cosmos DB
- Azure Database for MySQL server
- Service Bus
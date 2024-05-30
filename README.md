# CAM Azure Stack Deployment Template



[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https:%2F%2Fraw.githubusercontent.com%2FProsperoware%2Fcam-azure-deployment%2Ffeature-CLOUD-29414_master%2FazureDeploy.json)



## CAM Azure Stack Architecture
![](https://github.com/Prosperoware/cam-azure-deployment/blob/master/Archi.png)
test push

## Azure Resources
When you deploy this Azure Resource Manager template, the following resources will be created:
* Storage Account: this is the main storage account that is used to create 2 storage blobs
    * Application Config Storage BLOB container to keep application configuration files
    * Encryption Scope to encrypt the temporary data in the data stroage BLOB
    * Data Storage BLOB container with the encryption scope to keep the data at rest
* Azure Database for MySQL server
    * Default database
* Cosmos
    * Cosmos DB
        * Containers:
            * tenant
            * etl-auth
            * etl-job
            * etl-job-items
            * etl-mapping
            * etl-office-subscription
            * systemauth
* Service Bus
    * Queue
    * Topics:
        * Renewal
        * Mapping
        * Reload
* Web Server:
    * Function Apps:
        * API App
        * Renewal App
        * Mapping App
        * Process App

## Template Parameters
* Is Production: Yes/No
* Environment Stage: dev/qa/stg/prod
* Top Level Domain: io/eu/com
* Instance Unique Name: All resources on Azure should be unique, use this to match CAM url (e.g. contentsync)
* MySQL administrator Login
* MySQL administrator Login Password

## Resources' Naming Convention Variables
* Common Id: <UniqueName> + <Stage> + <TLD> (e.g. contentsyncdevio)
* Resources Namespace: <UniqueName> + "-" + <Stage> + "-" + <TLD> (e.g. contentsync-dev-io)
* Storage Account: "strg" + <CommonId> (e.g. strgcontentsyncdevio)
    * Application Config Bucket: <NS> + "-application-config" (e.g. contentsync-dev-io-application-config)
    * Encryption Scope: DataAtRest
    * Encrypted Bucket: <NS> + "-encrypted-bucket" (e.g. contentsync-dev-io-encrypted-bucket)
* MySQL server name: "mysql-" + <NS> (e.g. mysql-contentsync-dev-io)
    * MySQL default database: <CommonId> (e.g. contentsyncdevio)
* Cosmos Name: "cosmos-" + <NS>  (e.g. cosmos-contentsync-dev-io)
    * Cosmos Database Name: <CommonId> (e.g. contentsyncdevio)
* Service Bus Name: "servicebus-" + <NS> (e.g. servicebus-contentsync-dev-io)
    * Queue Name: <NS> + "-etl-process-v1" (e.g. contentsync-dev-io-etl-process-v1)
    * Service Bus Topics:
        * Mapping: <NS> + "-etl_mapping_worker_start" (e.g. contentsync-dev-io-etl_mapping_worker_start)
        * Renewal: <NS> + "-etl_renewal_worker_start" (e.g. contentsync-dev-io-etl_renewal_worker_start)
        * Reload: <NS> + "-systemauth_reload" (e.g. contentsync-dev-io-systemauth_reload)
* Web Server: <NS> + "-api-app-srvr" (e.g. contentsync-dev-io-api-app)
    * API Function App: <NS> + "-etl-api" (e.g. contentsync-dev-io-etl-api)
    * Renewal Function App: <NS> + "-etl-renewal" (e.g. contentsync-dev-io-etl-renewal)
    * Mapping Function App: <NS> + "-etl-mapping" (e.g. contentsync-dev-io-etl-mapping)
    * Resources Function App: <NS> + "-etl-process" (e.g. contentsync-dev-io-etl-process)

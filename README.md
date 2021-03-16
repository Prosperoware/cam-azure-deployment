# CAM Azure Stack Deployment Template


[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https:%2F%2Fraw.githubusercontent.com%2FProsperoware%2Fcam-azure-deployment%2Fmaster%2FazureDeploy.json)

When you deploy this Azure Resource Manager template, the following entities will be created:
* Storage Account
    * Storage blob container to keep application configuration files
    * Encryption Scope
    * Storage BLOB container with the encryption scope to keep the data at rest
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
* Azure Database for MySQL server
* Service Bus
    * Queue
    * Topics:
        * Renewal
        * Mapping
        * Reload
* Web Server
    * Site
        * Functions:
            * activateMapping
            * checkHealth
            * crearteSubscription
            * createEtlJobs
            * createJob
            * createMapping
            * createSearchEntity
            * deleteMapping
            * etlJobProcessDLHandler
            * etlJobProcessHandler
            * etlMappingJobManagerHandler
            * etlMappingJobWorkerHandler
            * etlRenewalManagerHandler
            * etlRenewalWorkerHandler
            * getAuthToken
            * getEtlJobStatus
            * getMapping
            * getMappingJobsById
            * getMappingJobsByMappingId
            * getMappingStatus
            * handleValidation
            * jobSetting
            * listMappingJobs
            * replaceShortCutMapping
            * retryMapping
            * saveEtlAuthDetails
            * searchEntitySrcExtObjectId
            * searchMappingJobs
            * subscriptionCount

![](https://github.com/Prosperoware/cam-azure-deployment/blob/master/Archi.png)


Parameters:
* Is Production: Yes/No
* Environment Stage: dev/qa/stg/prod
* Top Level Domain: io/eu/com
* MySQL administrator Login
* MySQL administrator Login Password

Variables:
* Common Id: "contentsync" + <Stage> + <TLD> (e.g. contentsyncdevio)
* Resources Namespace: "contentsync-" + <Stage> + "-" + <TLD> (e.g. contentsync-dev-io)
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
* Storage Account: "strg" + <CommonId> (e.g. strgcontentsyncdevio)
    * Encryption Scope: DataAtRest
    * Application Config Bucket: <NS> + "-application-config" (e.g. contentsync-dev-io-application-config)
    * Encrypted Bucket: <NS> + "-encrypted-bucket" (e.g. contentsync-dev-io-encrypted-bucket)
* Web Server: <NS> + "-api-app-srvr" (e.g. contentsync-dev-io-api-app)
    * Web Site: <NS> + "-etl-api" (e.g. contentsync-dev-io-etl-api)
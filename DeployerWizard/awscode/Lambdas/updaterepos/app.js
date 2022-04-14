

let event={
    "version": "2.0",
    "routeKey": "POST /updaterepos",
    "rawPath": "/dev/updaterepos",
    "rawQueryString": "",
    "headers": {
        "accept": "application/json, text/plain, */*",
        "content-length": "19",
        "content-type": "application/json",
        "host": "o1ee6xf964.execute-api.us-east-1.amazonaws.com",
        "user-agent": "axios/0.21.4",
        "x-amzn-trace-id": "Root=1-624f2375-51ec8b644cec892f05c32ddc",
        "x-forwarded-for": "20.22.234.239",
        "x-forwarded-port": "443",
        "x-forwarded-proto": "https"
    },
    "requestContext": {
        "accountId": "236297122403",
        "apiId": "o1ee6xf964",
        "domainName": "o1ee6xf964.execute-api.us-east-1.amazonaws.com",
        "domainPrefix": "o1ee6xf964",
        "http": {
            "method": "POST",
            "path": "/dev/updaterepos",
            "protocol": "HTTP/1.1",
            "sourceIp": "20.22.234.239",
            "userAgent": "axios/0.21.4"
        },
        "requestId": "QOJ6YinZIAMEMhg=",
        "routeKey": "POST /updaterepos",
        "stage": "dev",
        "time": "07/Apr/2022:17:46:29 +0000",
        "timeEpoch": 1649353589484
    },
    "body": "{\"type\":\"premium\"}",
    "isBase64Encoded": false
}
console.log(JSON.stringify(event));


process.env.AWSREGION = 'us-east-1'
process.env.RUNNINGLOCALLY=true;
process.env.DYNAMOTABLE = 'CFAzureDeployerInfo';
process.env.TABLE_LOGS = 'CFAzureDeployerLog';
process.env.standardurl = 'https://raw.githubusercontent.com/Prosperoware/cam-azure-deployment/qa2test/azureDeploy.json'
process.env.premiumurl = 'https://raw.githubusercontent.com/Prosperoware/cam-azure-deployment/qa2test/azureDeploy.json'

var lambda = require("./updaterepos/index.js");
arranca(event)

async function arranca(event){

    let res = lambda.handler(event).then((data) => {
        console.log(JSON.stringify(data));
    });
}
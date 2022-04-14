


let event={
    "version": "2.0",
    "routeKey": "POST /customer",
    "rawPath": "/customer",
    "rawQueryString": "",
    "headers": {
        "accept": "*/*",
        "accept-encoding": "gzip, deflate, br",
        "cache-control": "no-cache",
        "content-length": "351",
        "content-type": "application/json",
        "host": "8d1s7gb0y9.execute-api.us-east-1.amazonaws.com",
        "postman-token": "7316c8d4-4209-492d-9aae-0719e1edcc49",
        "user-agent": "PostmanRuntime/7.28.4",
        "x-amzn-trace-id": "Root=1-61d87bde-3161efdd610356b96c2313b3",
        "x-forwarded-for": "201.110.27.19",
        "x-forwarded-port": "443",
        "x-forwarded-proto": "https"
    },
    "requestContext": {
        "accountId": "161319209275",
        "apiId": "8d1s7gb0y9",
        "domainName": "8d1s7gb0y9.execut∂e-api.us-east-1.amazonaws.com",
        "domainPrefix": "8d1s7gb0y9",
        "http": {
            "method": "POST",
            "path": "/customer",
            "protocol": "HTTP/1.1",
            "sourceIp": "201.110.27.19",
            "userAgent": "PostmanRuntime/7.28.4"
        },
        "requestId": "LlhKviSIoAMEMzw=",
        "routeKey": "POST /customer",
        "stage": "$default",
        "time": "07/Jan/2022:17:43:58 +0000",
        "timeEpoch": 1641577438129
    },
    "body": "{\n    \"prosperoTenantid\": \"c515b276-8f75-48c4-bb59-a2d9379e6a78\",\n    \"url\": \"https://dev.azure.com/xherstone\",\n    \"pat\": \"3lolveloh534dotfcnuxvvy3ows6c6zmocnrgvrpgif4jeuwwxxq\",\n    \"reponame\": \"pros61810\",\n    \"repoid\": \"bed1f7f5-18a0-4591-8078-2f1b7514179a\",\n    \"projectName\": \"pros61810\",\n    \"projectid\": \"a4de6478-5fba-45f4-83b5-080edcbd3d32\"\n}",
    "isBase64Encoded": false
}
console.log(JSON.stringify(event));


process.env.RUNNINGLOCALLY=true;
process.env.AWSREGION = 'us-east-1'
process.env.DYNAMOTABLE = 'AzureDeployerInfo';

var lambda = require("./postcustomer/index.js");
arranca(event);

async function arranca(event){

    let res = lambda.handler(event).then((data) => {
        console.log(JSON.stringify(data));
    });
}
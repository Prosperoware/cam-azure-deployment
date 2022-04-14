

let event={
    "version": "2.0",
    "type": "REQUEST",
    "routeArn": "arn:aws:execute-api:us-east-1:161319209275:8d1s7gb0y9/$default/POST/customer",
    "identitySource": [
        "a525b276-8f75-48c4-bb59-a2d9379e6a78",
        "a525b276-8f75-48c4-bb59-a2d9379e6a78"
    ],
    "routeKey": "POST /customer",
    "rawPath": "/customer",
    "rawQueryString": "",
    "headers": {
        "accept": "*/*",
        "accept-encoding": "gzip, deflate, br",
        "authorization": "authorization213241234",
        "cache-control": "no-cache",
        "content-length": "345",
        "content-type": "application/json",
        "host": "8d1s7gb0y9.execute-api.us-east-1.amazonaws.com",
        "postman-token": "affb6906-b354-4be2-9ce1-72732bb7dffa",
        "tenantid": "a525b276-8f75-48c4-bb59-a2d9379e6a78",
        "user-agent": "PostmanRuntime/7.29.0",
        "x-amzn-trace-id": "Root=1-62028efb-5021820c1fee56ee58240899",
        "x-forwarded-for": "201.110.62.53",
        "x-forwarded-port": "443",
        "x-forwarded-proto": "https"
    },
    "requestContext": {
        "accountId": "161319209275",
        "apiId": "8d1s7gb0y9",
        "domainName": "8d1s7gb0y9.execute-api.us-east-1.amazonaws.com",
        "domainPrefix": "8d1s7gb0y9",
        "http": {
            "method": "POST",
            "path": "/customer",
            "protocol": "HTTP/1.1",
            "sourceIp": "201.110.62.53",
            "userAgent": "PostmanRuntime/7.29.0"
        },
        "requestId": "NOtHXhfTIAMEJgA=",
        "routeKey": "POST /customer",
        "stage": "$default",
        "time": "08/Feb/2022:15:40:43 +0000",
        "timeEpoch": 1644334843721
    }
}

console.log(JSON.stringify(event));


process.env.AWSREGION = 'us-east-1'
process.env.RUNNINGLOCALLY=true;
process.env.DYNAMOTABLE = 'AzureDeployerInfo';

var lambda = require("./AzureAuthorizer/index.js");
arranca(event)

async function arranca(event){

    let res = lambda.AzureAuthorizer(event).then((data) => {
        console.log(JSON.stringify(data));
    });
}



let event=
{
    "version": "2.0",
    "routeKey": "POST /customer",
    "rawPath": "/customer",
    "rawQueryString": "",
    "headers": {
        "accept": "application/json",
        "authorization": "sc325b276-8f75-48c4-bb59-a2d9379e6a78",
        "content-length": "306",
        "content-type": "application/json; charset=utf-8",
        "host": "8d1s7gb0y9.execute-api.us-east-1.amazonaws.com",
        "tenantid": "c425b276-8f75-48c4-bb59-a2d9379e6a78",
        "x-amzn-trace-id": "Root=1-62066f31-100c472e28cba6ba0ffd0de7",
        "x-forwarded-for": "23.98.138.10",
        "x-forwarded-port": "443",
        "x-forwarded-proto": "https"
    },
    "requestContext": {
        "accountId": "161319209275",
        "apiId": "8d1s7gb0y9",
        "authorizer": {
            "lambda": {
                "booleanKey": true,
                "numberKey": 123,
                "stringKey": "stringval"
            }
        },
        "domainName": "8d1s7gb0y9.execute-api.us-east-1.amazonaws.com",
        "domainPrefix": "8d1s7gb0y9",
        "http": {
            "method": "POST",
            "path": "/customer",
            "protocol": "HTTP/1.1",
            "sourceIp": "23.98.138.10",
            "userAgent": ""
        },
        "requestId": "NYZPxihOIAMEM5w=",
        "routeKey": "POST /customer",
        "stage": "$default",
        "time": "11/Feb/2022:14:14:09 +0000",
        "timeEpoch": 1644588849572
    },
    "body": "{\"prosperoTenantid\":\"c425b276-8f75-48c4-bb59-a2d9379e6a78\",\"url\":\"https://dev.azure.com/xherstone\",\"pat\":\"pfuft2bs3ov7vfb3pisdc3nlbinwp2lmm6xh5kwi4vopfkiffgtq\",\"reponame\":\"prosjue4\",\"repoid\":\"b16b7b76-36de-41e2-84f5-8df6172a64bf\",\"projectName\":\"prosjue4\",\"projectid\":\"15a908f2-ea9f-4892-8dc1-c4292d2e4ed3\"}",
    "isBase64Encoded": false
}

console.log(JSON.stringify(event));


process.env.AWSREGION = 'us-east-1'
process.env.RUNNINGLOCALLY=true;
process.env.DYNAMOTABLE = 'AzureDeployerInfo';

var lambda = require("./validatecustomer/index.js");
arranca(event);

async function arranca(event){

    let res = lambda.handler(event).then((data) => {
        console.log(JSON.stringify(data));
    });
}
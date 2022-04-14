

let event=
{
    "version": "2.0",
    "routeKey": "POST /report",
    "rawPath": "/report",
    "rawQueryString": "",
    "headers": {
        "authtoken": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6Im9PdmN6NU1fN3AtSGpJS2xGWHo5M3VfVjBabyJ9.eyJuYW1laWQiOiI5NzRmZTcyMi03M2FiLTRlYWUtOGY0Zi1mNTk4ZWE4OWMxM2IiLCJzY3AiOiJhcHBfdG9rZW4iLCJhdWkiOiIzZmRkNTMxNi0yNWZiLTRjOTQtOWJlZS0xN2U3MGI2MzkxMGYiLCJzaWQiOiJjYzBlY2Y0YS0yYzk4LTRmZjgtYTk3MS1iMDE2YzA5ZmQ3OTIiLCJCdWlsZElkIjoiMmJiYmFkMTUtM2FiYS00M2UyLTg3YmItMGZjM2JlYjAxZGM5Ozg4MDciLCJwcGlkIjoidnN0ZnM6Ly8vQnVpbGQvQnVpbGQvODgwNyIsIm9yY2hpZCI6ImMzMGFkYWJkLTE0YzUtNGJlNi1iMDE0LTliZDkxNjk4Njk2OC5kZXBsb3kuZGVwbG95bWVudGpvYi5vbnN1Y2Nlc3MuaW52b2tlcmVzdGFwaSIsInJlcG9JZHMiOiI2OWY4NmU4OS1lMWI1LTQ4ZGItOTA3OS1kYmJiMmU3ZDRkYzUiLCJpc3MiOiJhcHAudnN0b2tlbi52aXN1YWxzdHVkaW8uY29tIiwiYXVkIjoiYXBwLnZzdG9rZW4udmlzdWFsc3R1ZGlvLmNvbXx2c286NTEwZTgxMTQtMjFiMS00YTkxLWJmZGMtM2VkZTZmN2FmMTZmIiwibmJmIjoxNjQzNTkzNjMzLCJleHAiOjE2NDM1OTg0MzN9.oW6xuW-hK1cSKEgm76DWz_mmAM0fO1A83tlragwiLIrHz6zAZm-bGyX6hhL2ndsQoZjdVKNb6FOOBnFkbSdWUwMHVsZv9aNS08Eswdfrmwy4jAwzUAbamULSlCWfo7w38fiYbbMRfCJCu5W6z9I-oTyjg7vV3noh8nhvQJN5lhPMlreWG1qbzQmhVLHyGvBKinMS5AS3UyoKuLYHSGowAKorJg8f9zFEWgWw_pAMgeuryGCtjrEJ1hwXQAQ94jYS2xtRH54IrjOm5eGjl7veAJumqYPpmKXkcFSp0Je54oGPHNl9u8LUIiwsNpra6Mexmb49nH_GaTKmzl1cRq518Q",
        "content-length": "45",
        "content-type": "application/json",
        "host": "8d1s7gb0y9.execute-api.us-east-1.amazonaws.com",
        "hubname": "build",
        "jobid": "cfd2f1c2-1fb0-5ec8-079d-332b32b21063",
        "planid": "c30adabd-14c5-4be6-b014-9bd916986968",
        "planurl": "https://dev.azure.com/xherstone/",
        "projectid": "2bbbad15-3aba-43e2-87bb-0fc3beb01dc9",
        "request-context": "appId=cid-v1:e3d45cd2-3b08-46bc-b297-cda72fdc1dc1",
        "request-id": "|11aaea8b34cc92478d20399896177010.8dab13426b359d4d.",
        "taskinstanceid": "0f135420-0932-5d5f-521c-9a5b425c34cd",
        "timelineid": "c30adabd-14c5-4be6-b014-9bd916986968",
        "traceparent": "00-11aaea8b34cc92478d20399896177010-8dab13426b359d4d-00",
        "user-agent": "VSTS_510e8114-21b1-4a91-bfdc-3ede6f7af16f_Build_ServerExecution_HttpRequest",
        "x-amzn-trace-id": "Root=1-61f741f8-5cf78232323039b9366dfef0",
        "x-forwarded-for": "20.41.6.12",
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
            "path": "/report",
            "protocol": "HTTP/1.1",
            "sourceIp": "20.41.6.12",
            "userAgent": "VSTS_510e8114-21b1-4a91-bfdc-3ede6f7af16f_Build_ServerExecution_HttpRequest"
        },
        "requestId": "Myc-5jLloAMEJQA=",
        "routeKey": "POST /report",
        "stage": "$default",
        "time": "31/Jan/2022:01:57:12 +0000",
        "timeEpoch": 1643594232731
    },
    "body": "{\n  \"tenantid\":\"a7344920-d955-11e9-80cc-ab5f4297279a\",\n  \"status\":\"sucess\"\n}\n",
    "isBase64Encoded": false
};

console.log(JSON.stringify(event));


process.env.AWSREGION = 'us-east-1'
process.env.RUNNINGLOCALLY=true;
process.env.TABLE_LOGS = 'CFAzureDeployerLog';
process.env.DYNAMOTABLE = 'CFAzureDeployerInfo';

var lambda = require("./report/index.js");
arranca(event)

async function arranca(event){

    let res = lambda.handler(event).then((data) => {
        console.log(JSON.stringify(data));
    });
}
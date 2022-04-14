

const axios = require('axios');
var AWS = require("aws-sdk");
var uuid = require("uuid")

var crypto = require('crypto');
const algorithm = 'aes-256-cbc';
const secret = 'shezhuansauce';
const keyga = crypto.createHash('sha256').update(String(secret)).digest('base64');
const key = Buffer.from(keyga, 'base64')
const iv = crypto.randomBytes(16);

if (process.env.RUNNINGLOCALLY === 'true') {
    var credentials = new AWS.SharedIniFileCredentials({ profile: 'dev' });
    AWS.config.credentials = credentials;
}

var documentClient = new AWS.DynamoDB.DocumentClient({ 'region': process.env.AWSREGION });
exports.handler = async (event) => {


    console.log(JSON.stringify(event));
    let body = JSON.parse(event.body);

    let template = body.type;

    switch (template) {
        case 'standard':
            template='Standard';
            console.log('Updating Standard deployments');
            break;
        case 'premium':
            template='Premium';
            console.log('Updating Premium deployments');
            break;
        default:
            console.log('Option not valid');
        // code
    }


    try {

        let catalog = await GetCustomer(template)

        let templateBase64 = await GetLastARMTemplate(template);
        if (templateBase64 === "") {
            console.log('Can not download the last template');
            return;
        }
        console.log('1 - updating ' + catalog.length);
        for (let index = 0; index < catalog.length; index++) {
            const element = catalog[index];
            console.log(JSON.stringify(element));
            let patdecripted;
            const de = new Date().getTime()
            const today = new Date().toJSON();
            var log = {
                Logid: uuid.v1(),
                tenantid: element.prosperoTenantid,
                version: body.after,
                url: element.url,
                reponame: element.reponame,
                projectname: element.projectName,
                date: de,
                datef: today,
                status: ''
            }
            var paramput = {
                TableName: process.env.TABLE_LOGS,
                Item: log

            }

            try {
                console.log('lets decript')
                patdecripted = decrypt(element.pat);
                console.log('decripted')

            } catch (error) {

                log.status = 'error'
                log.statusDetail = 'SecretNotFound - ' + error.message
                paramput.Item = log;
                let espera = await documentClient.put(paramput).promise();
                continue;
            }

            element.pat = patdecripted;
            let res = await GetLastCommit(element);

            switch (res.status) {
                case 200:

                    let res3 = await Pushcommit(element, res.data.value[0].commitId, templateBase64);
                    if (res3.status === 201) {

                        log.status = 'success'


                    }
                    else {
                        log.status = 'error'
                    }

                    try {
                        paramput.Item = log;
                        console.log('SAving logs');
                        let espera = await documentClient.put(paramput).promise();
                    } catch (error) {
                        console.log('error')
                    }
                    break;
                case 404: // not found
                    console.log('The tenant devops url was not found ' + element.prosperoTenantid + ' url-> ' + element.url);
                    log.status = 'NotFound'
                    try {
                        paramput.Item = log;
                        let espera = await documentClient.put(paramput).promise();
                        let x=0;
                    } catch (error) {
                        console.log('Error in Dynamodb log. We were not able to put the log.')
                        console.log(error)
                    }
                case 401:
                    console.log('Error The tenant devops url permission denied ' + element.prosperoTenantid + ' url-> ' + element.url);
                    log.status = 'Unauthorized'
                    try {
                        paramput.Item = log;
                        let espera = await documentClient.put(paramput).promise();
                    } catch (error) {
                        console.log('error')
                    }
                    break;
                default:

                    break
            }

        }

        console.log('Finish');

    } catch (error) {
        console.log('Error when trying to process the tenant update' + error);
        return ErrorResponse({ mesage: 'Error' }, 500);
    }


}

async function GetCustomer(template) {

    var content;
    try {

        var paramswf = {
            TableName: process.env.DYNAMOTABLE,
            FilterExpression: '#templateddeployed = :templateddeployed',
            ExpressionAttributeNames: {
                '#templateddeployed': 'templateddeployed',
            },
            ExpressionAttributeValues: {
                ':templateddeployed': template,
            },
        };
        var params = {
            TableName: process.env.DYNAMOTABLE,
            
        };
        var content = await documentClient.scan(params).promise();
        return content.Items;

    } catch (error) {
        console.log('Error while getting customers');
        return error;
    }


}

async function GetLastCommit(evento) {
    try {

        console.log('Getting last commit from azure.')
        var url = evento.url + '/' + evento.projectid + '/_apis/git/repositories/' + evento.repoid + '/commits?searchCriteria.$top=1&api-version=6.0';
        var key = Buffer.from(':' + evento.pat).toString('base64')
        console.log('Getting Last Commit' + JSON.stringify(evento));
        var config = {
            method: 'get',
            url: url,
            headers: {
                'Authorization': 'Basic ' + key
            },

        };
        var res = await axios(config);
        console.log('Success getting last commit');

        return res;
    } catch (error) {
        console.log('Error on get lats commit');
        console.log(error)
        return error.response;
    }
}
async function Pushcommit(evento, lastcommit, templateBase64) {
    try {



        console.log('Pushing new commit' + JSON.stringify(evento));
        let commit = {
            "changeType": "edit",
            "item": {
                "path": "/azureDeploy.json"
            },
            "newContent": {
                "content": templateBase64,
                "contentType": "base64encoded"
            }
        };
        const d = new Date();
        let pushschema = {
            "refUpdates": [
                {
                    "name": "refs/heads/master",
                    "oldObjectId": lastcommit
                }
            ],
            "commits": [
                {
                    "comment": 'New commit ' + d.getTime(),
                    "changes": [

                    ]
                }
            ]
        };
        pushschema.commits[0].changes.push(commit);
        var key = Buffer.from(':' + evento.pat).toString('base64')
        let urlazure = evento.url + '/_apis/git/repositories/' + evento.repoid + '/pushes?api-version=6.0';
        var config2 = {
            method: 'post',
            url: urlazure,
            headers: {
                'Authorization': 'Basic ' + key
            },
            data: pushschema
        };
        //var res = await axios(config2);

        console.log('Pushed!')
        return res;
    } catch (error) {
        console.log('Error in push commit');
        console.log(error)
        return error.response;
    }
}


async function GetLastARMTemplate(template) {
    try {
        console.log('Downloading template ' + template);
        var url='';
        switch (template) {
            case 'Standard':
                url = process.env.standardurl;//"https://raw.githubusercontent.com/courfeyrak/testgit/master/azureDeploy.json";        
                break;
            case 'Premium':
                url =process.env.premiumurl;//"https://raw.githubusercontent.com/courfeyrak/testgit/master/azureDeploy.json";        
                break;
            default:
                break;
        }
        


        var config = {
            method: 'get',
            url: url
        };
        var res = await axios(config);
        var updatedcode = "";
        if (res.status == 200) {
            var newcode = res.data;
            updatedcode = Buffer.from(newcode).toString('base64')
            console.log('Downloading template 2');
        }
        else {
            console.log('Downloading template 3 vacio');
        }

        return updatedcode;
    } catch (error) {
        console.log('Downloading template error ');
        console.log(error)
        return "";
    }
}

async function GetSecret(arnsecret) {

    return new Promise(async (resolve, reject) => {
        var secretsmanager = new AWS.SecretsManager({
            region: process.env.AWSREGION
        });

        var params = {
            SecretId: arnsecret
        };


        try {

            let sec = await secretsmanager.getSecretValue(params).promise();
            resolve(sec);
            console.log(JSON.stringify(sec));
        } catch (error) {

            console.log('Error creating the secret');
            reject(error);

        }
    });
}


var headers = {
    "Content-Type": "application/json"
}

/**
 * Create a success response
 * @param {Number} statusCode http status code
 * @param {object} body response body
 * @returns {object} Success response
 */
function OkResponse(body = {}, statusCode = 200) {

    return {
        headers: headers,
        statusCode: statusCode,
        body: JSON.stringify(body)
    }
}
/**
 * Create Error response object
 * @param {Number} statusCode http status code
 * @param {object} message error description
 * @returns {object} Error responses
 */
function ErrorResponse(message, statusCode) {
    return {
        headers: headers,
        statusCode: statusCode,
        body: JSON.stringify({
            message: message
        })
    }
}

function decrypt(text) {

    let iv = Buffer.from(text.iv, 'hex');
    let encryptedText =
        Buffer.from(text.encryptedData, 'hex');

    // Creating Decipher
    let decipher = crypto.createDecipheriv(
        'aes-256-cbc', Buffer.from(key), iv);

    // Updating encrypted text
    let decrypted = decipher.update(encryptedText);
    decrypted = Buffer.concat([decrypted, decipher.final()]);

    // returns data after decryption
    return decrypted.toString();
}
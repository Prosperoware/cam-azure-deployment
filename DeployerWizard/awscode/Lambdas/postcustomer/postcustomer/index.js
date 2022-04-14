

const axios = require('axios');
var AWS = require("aws-sdk");

if (process.env.RUNNINGLOCALLY === 'true') {
    var credentials = new AWS.SharedIniFileCredentials({ profile: 'xher' });
    AWS.config.credentials = credentials;
}
var crypto = require('crypto');
const algorithm = 'aes-256-cbc';
const secret = 'shezhuansauce';
const keyga = crypto.createHash('sha256').update(String(secret)).digest('base64');
const key = Buffer.from(keyga, 'base64')
const iv = crypto.randomBytes(16);

exports.handler = async (event) => {
    try {

        console.log(JSON.stringify(event));
        let b = JSON.parse(event.body);
        let espera;
        var documentClient = new AWS.DynamoDB.DocumentClient({ 'region': process.env.AWSREGION });
        var response = {};
        try {

            try {

                var params = {
                    TableName: process.env.DYNAMOTABLE,
                    KeyConditionExpression: 'prosperoTenantid = :hkey',
                    ExpressionAttributeValues: {
                        ':hkey': b.prosperoTenantid,
                    }
                };

                espera = await documentClient.query(params).promise();

            } catch (error) {
                console.log('File not found');
                content = '[]';
            }
            console.log('Find');
            if (espera.Count === 0) { //costumer does not exists
                console.log('Adding customer');
                let info = {

                }

                console.log('2');    
                info.prosperoTenantid = b.prosperoTenantid;
                info.reponame = b.reponame;
                info.repoid = b.repoid;
                info.projectName = b.projectName;
                info.url = b.url;
                info.projectid = b.projectid;
                info.domain=b.prostenantdomain;
                info.templateddeployed=b.templateddeployed;
                let res;
                try {
                    console.log(JSON.stringify(b));
                    res = encrypt(b.pat, key, iv);
                    console.log('3');

                } catch (error) {
                    console.log('Cannot generate Secret '+ error)
                    response.status = 'Error';
                    response.mesage = 'Error creating customer'
                    response.data = error;
                    return ErrorResponse(response, 500);
                }
                info.pat = res;
                console.log(JSON.stringify(info));
                
                var paramput = {
                    TableName: process.env.DYNAMOTABLE,
                    Item: info
                }

                espera = await documentClient.put(paramput).promise();
                response.status = 'sucess';
                return OkResponse(response);

            }
            else {
                console.log('Customer is already subscribed to the service.')
                response.status = 'duplicated';
                response.mesage = 'customer already exists'
                response.data = b;
                return OkResponse(response);
            }
            

        } catch (error) {
            console.log('Error al intentar leer el s3' + error);
            return ErrorResponse({ mesage: 'Error' }, 500);
        }


    } catch (error) {
        console.log('NO SE PUDO CREAR al usuario en la db ', error);
        return ErrorResponse({ mesage: 'Error' }, 500);

    }

}
var headers = {
    "Content-Type": "application/json"
}

async function EncriptSecret(data) {

    try {

        return data.pat;
    } catch (error) {

    }

}

async function createSecret(data) {

    return new Promise(async (resolve, reject) => {
        var secretsmanager = new AWS.SecretsManager({
            region: process.env.AWSREGION
        });
        var params = {
            ClientRequestToken: "EXAMPLE1-90ab-cdef-fedc-ba987SECRET1",
            Description: "Secret for content Mover",
            Name: data.prosperoTenantid + "_" + new Date().getTime(),
            SecretString: JSON.stringify(data)
        };

        try {

            let sec = await secretsmanager.createSecret(params).promise();
            resolve(sec);
            console.log(JSON.stringify(sec));
        } catch (error) {

            console.log('Error creating the secret');
            reject(error);

        }
    });
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


function encrypt(text, key, iv) {

    // Creating Cipheriv with its parameter
    let cipher =
        crypto.createCipheriv('aes-256-cbc', Buffer.from(key), iv);

    // Updating text
    let encrypted = cipher.update(text);

    // Using concatenation
    encrypted = Buffer.concat([encrypted, cipher.final()]);

    // Returning iv and encrypted data
    return {
        iv: iv.toString('hex'),
        encryptedData: encrypted.toString('hex')
    };
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
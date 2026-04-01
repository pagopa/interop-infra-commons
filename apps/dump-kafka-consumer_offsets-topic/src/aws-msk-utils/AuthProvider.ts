// src/AuthProvider.ts
const { generateAuthToken } = require('aws-msk-iam-sasl-signer-js');

// Change return type to Promise<string>
export async function oauthBearerTokenProvider(region: string): Promise<any> {
    console.log("Generating MSK IAM token for region:", region);
    
    try {
        const result = await generateAuthToken({ region });
        // result.token is the base64 encoded MSK IAM token string
        const tokenValue = result.token; 
        const lifetime = result.expiryTime;
        console.debug(`Token fetched from AWS expires at ${lifetime}`,);
        return { tokenValue, lifetime };
    } catch (err) {
        console.error("Errore generazione token IAM:", err);
        throw err;
    }
}

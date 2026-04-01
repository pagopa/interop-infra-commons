import { Logger } from "pino";

// src/AuthProvider.ts
const { generateAuthToken } = require('aws-msk-iam-sasl-signer-js');

// Change return type to Promise<string>
export async function oauthBearerTokenProvider(logger: Logger, region: string): Promise<any> {
    logger.info("Generating MSK IAM token for region: " + region);
    
    try {
        const result = await generateAuthToken({ region });
        // result.token is the base64 encoded MSK IAM token string
        const tokenValue = result.token; 
        const lifetime = result.expiryTime;
        logger.debug(`Token fetched from AWS expires at ${lifetime}`,);
        return { tokenValue, lifetime };
    } catch (err) {
        logger.error("Errore generazione token IAM:" + (err as Error)?.message + "\n" + (err as Error)?.stack );
        throw err;
    }
}

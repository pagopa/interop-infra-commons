import { Logger } from "pino";

// src/AuthProvider.ts
const { generateAuthToken } = require('aws-msk-iam-sasl-signer-js');

interface TokenData {
    tokenValue: string;
    lifetime: number;
}

// Provides token data for the OAuth bearer token callback.
export async function oauthBearerTokenProvider(logger: Logger, region: string): Promise<TokenData> {
    logger.info("Generating MSK IAM token for region: " + region);
    
    try {
        const result = await generateAuthToken({ region });
        // result.token is the base64 encoded MSK IAM token string
        const tokenValue = result.token; 
        const lifetime = result.expiryTime;
        logger.debug(`Token fetched from AWS expires at ${lifetime}`,);
        return { tokenValue, lifetime };
    } catch (err) {
        logger.error("Error generating token IAM:" + (err as Error)?.message + "\n" + (err as Error)?.stack );
        throw err;
    }
}

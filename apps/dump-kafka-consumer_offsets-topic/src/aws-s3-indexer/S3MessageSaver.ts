import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { randomUUID } from 'crypto';
import { IMessageSaver, MessageEntry } from './types';

export class S3MessageSaver implements IMessageSaver {
    private s3Client: S3Client;

    constructor( region: string) {
        this.s3Client = new S3Client({ region });
    }

    async saveMessages(baseUrl: string, messages: MessageEntry[]): Promise<string[]> {
        const url = new URL(baseUrl);
        
        if (url.protocol !== 's3:') {
            throw new Error(`Unsupported URL schema for S3MessageSaver: ${baseUrl}`);
        }

        const bucket = url.hostname;
        let basePath = url.pathname.substring(1); 
        if (basePath.endsWith('/')) basePath = basePath.slice(0, -1);

        const createdResources: string[] = [];
        const groupedMessages = new Map<string, string[]>();

        for (const msg of messages) {
            // Parse the string into an integer representing epoch seconds
            const epochMilliseconds = parseInt(msg.ts, 10);
            
            if (isNaN(epochMilliseconds)) {
                throw new Error(`Invalid epoch milliseconds timestamp provided: ${msg.ts}`);
            }

            // JavaScript Date requires milliseconds, so multiply by 1000
            const date = new Date(epochMilliseconds);

            const yyyy = date.getUTCFullYear();
            const mm = String(date.getUTCMonth() + 1).padStart(2, '0');
            const dd = String(date.getUTCDate()).padStart(2, '0');
            const hh = String(date.getUTCHours()).padStart(2, '0');

            const jsonParsed = JSON.parse(msg.json);
            const kindField = jsonParsed.kind || 'NONE';

            const prefix = basePath ? `${basePath}/` : '';
            const keyPrefix = `${prefix}kind=${kindField}/year=${yyyy}/month=${mm}/day=${dd}/hour=${hh}`;

            if (!groupedMessages.has(keyPrefix)) {
                groupedMessages.set(keyPrefix, []);
            }
            groupedMessages.get(keyPrefix)!.push(msg.json);
        }

        for (const [keyPrefix, jsons] of groupedMessages.entries()) {
            const uuid = randomUUID();
            const key = `${keyPrefix}/${uuid}.ndjson`;
            const body = jsons.join('\n') + '\n'; 

            await this.s3Client.send(new PutObjectCommand({
                Bucket: bucket,
                Key: key,
                Body: body,
                ContentType: 'application/x-ndjson'
            }));

            createdResources.push(`s3://${bucket}/${key}`);
        }

        return createdResources;
    }
}

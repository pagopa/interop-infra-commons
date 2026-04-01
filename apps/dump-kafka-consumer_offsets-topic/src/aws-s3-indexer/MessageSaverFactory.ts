import { IMessageSaver } from './types';
import { S3MessageSaver } from './S3MessageSaver';

export class MessageSaverFactory {
    private static instance: MessageSaverFactory;

    // Private constructor to enforce Singleton pattern
    private constructor() {}

    /**
     * Returns the singleton instance of the MessageSaverFactory.
     */
    public static getInstance(): MessageSaverFactory {
        if (!MessageSaverFactory.instance) {
            MessageSaverFactory.instance = new MessageSaverFactory();
        }
        return MessageSaverFactory.instance;
    }

    /**
     * Provides a specific instance of IMessageSaver based on the URL schema.
     * @param baseUrl The URL defining the target storage.
     * @returns An instance implementing IMessageSaver.
     * @throws Error if the URL schema is not supported.
     */
    public getMessageSaver(baseUrl: string): IMessageSaver {
        let url: URL;
        try {
            url = new URL(baseUrl);
        } catch (error) {
            throw new Error(`Invalid URL provided: ${baseUrl}`);
        }

        switch (url.protocol) {
            case 's3:':
                return new S3MessageSaver();
            default:
                throw new Error(`Unsupported URL schema: ${url.protocol}//`);
        }
    }
}

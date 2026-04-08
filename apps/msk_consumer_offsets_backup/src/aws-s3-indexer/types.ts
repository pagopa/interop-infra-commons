// types.ts

/**
 * Data structure that contains a JSON on one line and an 
 * original message creation timestamp.
 */
export type MessageEntry = {
    readonly json: string;
    /** 
     * Original message creation timestamp. 
     * Represented as a string containing an epoch milliseconds number.
     */
    readonly ts: string; 
};

/**
 * Interface for classes used to save messages on specific storage.
 */
export interface IMessageSaver {
    /**
     * Saves messages to the specified storage.
     * @param baseUrl The base URL defining the storage location.
     * @param messages The array of messages to save.
     * @returns A promise that resolves to a list of created resources.
     */
    saveMessages(baseUrl: string, messages: MessageEntry[]): Promise<string[]>;
}

// Type definitions for @stomp/stompjs 4.x
// Project: https://github.com/stomp-js/stomp-websocket
// Definitions by: Jimi Charalampidis <https://github.com/jimic>
//                 Deepak Kumar <https://github.com/kum-deepak>
// Definitions: https://github.com/stomp-js/stomp-websocket/blob/master/index.d.ts

export const VERSIONS: {
    V1_0: string,
    V1_1: string,
    V1_2: string,
    supportedVersions: () => Array<string>
};

export class Client {
    connected: boolean;
    heartbeat: {
        incoming: number,
        outgoing: number
    };

    reconnect_delay: number;

    ws: any;

    debug(...args: string[]): any;

    connect(headers: StompHeaders, connectCallback: (frame?: Frame) => any, errorCallback?: (error: string) => any, closeCallback?: (event:CloseEvent) => any): any;
    connect(login: string, passcode: string, connectCallback: (frame?: Frame) => any, errorCallback?: (error: string) => any, closeCallback?: (event:CloseEvent) => any, host?: string): any;
    disconnect(disconnectCallback?: () => any, headers?: StompHeaders): any;

    send(destination: string, headers?: StompHeaders, body?: string): any;
    subscribe(destination: string, callback?: (message: Message) => any, headers?: StompHeaders): StompSubscription;
    onreceive: (message: Message) => void;
    onreceipt: (frame: Frame) => void;
    unsubscribe(id: string, headers?: StompHeaders): void;

    begin(transaction: string): any;
    commit(transaction: string): any;
    abort(transaction: string): any;

    ack(messageID: string, subscription: string, headers?: StompHeaders): any;
    nack(messageID: string, subscription: string, headers?: StompHeaders): any;
}

export interface StompSubscription {
    id: string;
    unsubscribe(headers?: StompHeaders): void;
}

export class StompHeaders { [key: string]: string }

export interface Message extends Frame {
    ack(headers?: StompHeaders): any;
    nack(headers?: StompHeaders): any;
}

export class Frame {
    constructor(command: string, headers?: StompHeaders, body?: string);

    command: string;
    headers: StompHeaders;
    body: string;

    toString(): string;
    static sizeOfUTF8(s: string): number;
    static unmarshall(datas: any): any;
    static marshall(command: string, headers?: StompHeaders, body?: string): any;
}

export function client(url: string, protocols?: string | Array<string>): Client;
export function over(ws: any | (() => any)): Client;

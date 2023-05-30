// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import * as amplitude from '@amplitude/analytics-browser';
import { CookieStorage } from '@amplitude/analytics-client-common';
import { MemoryStorage } from '@amplitude/analytics-core';
import { type Storage } from '@amplitude/analytics-types';

import { ApiKey, DefaultConfiguration } from './ampli';

const IS_PROD_ENV = process.env.NODE_ENV === 'production';
const environment = IS_PROD_ENV ? 'production' : 'development';
const apiKey = ApiKey[environment];

// 1. Ideal solution we agreed on: Anonymously track users before accepting ToS -> track users with cookies afterwards
// 2. Amplitude recommended solution: Queue events before accepting ToS -> track users with cookies afterwards and flush the queue (send all events)
// 3. Random idea #1: What if we did cookieless tracking in the wallet and just set a "userId" -> a hash of the user's main wallet address?
// 4. Random idea #2: Is there some solution where we store a unique ID in the service worker of the extension?

export async function initAmplitude() {
    amplitude.init(apiKey, undefined, {
        ...DefaultConfiguration,
        logLevel: IS_PROD_ENV
            ? amplitude.Types.LogLevel.Warn
            : amplitude.Types.LogLevel.Debug,
        // Amplitude sets some initial cookies on initialization, so disabling
        // this makes the initial cookies set in local storage. By plugging our
        // own cookie storage, this shooooouuuuuuld be set in memory??? FWIW,
        // they're removing this field in https://github.com/amplitude/Amplitude-TypeScript/pull/390
        disableCookies: true,
        // The idea is that we will use memory storage until the user
        // accepts the ToS (meaning the wallet is initialized), at which
        // point we'll use cookie storage and copy all of the session data over
        cookieStorage: new FlexibleCookieStorage(),
        // This is where un-sent and retried events are stored, this is in memory by default
        // but I'm just specifying it here to acknowledge this exists for this WIP
        storageProvider: new MemoryStorage(),
    });
}

export class FlexibleCookieStorage<T> implements Storage<T> {
    #memoryStorage: MemoryStorage<T>;
    #cookieStorage: CookieStorage<T>;

    constructor() {
        this.#memoryStorage = new MemoryStorage<T>();
        this.#cookieStorage = new CookieStorage<T>();
    }

    async isEnabled(): Promise<boolean> {
        return this.#getActiveStorage().isEnabled();
    }

    async get(key: string): Promise<T | undefined> {
        return this.#getActiveStorage().get(key);
    }

    async getRaw(key: string): Promise<string | undefined> {
        return this.#getActiveStorage().getRaw(key);
    }

    async set(key: string, value: T): Promise<void> {
        this.#getActiveStorage().set(key, value);
    }

    async remove(key: string): Promise<void> {
        this.#getActiveStorage().remove(key);
    }

    async reset(): Promise<void> {
        this.#getActiveStorage().reset();
    }

    #getActiveStorage() {
        // ??? need to get the Redux "isInitialized" state here...
        // Create an observable? plumb some global on the window? kind of blanking
        const isInitialized = false;

        // Basically,
        if (isInitialized) {
            console.log('WALLET IS INITIALIZED, GOIGN TO COOKIE STORAGE');
            console.log(this.#cookieStorage, this.#memoryStorage.memoryStorage);
            console.log(document.cookie);

            for (const [key, value] of this.#memoryStorage.memoryStorage) {
                console.log('SETTING', key, value);
                this.#cookieStorage.set(key, value);
            }
            this.#memoryStorage.reset();
        }
        return isInitialized ? this.#cookieStorage : this.#memoryStorage;
    }
}

// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import * as amplitude from '@amplitude/analytics-browser';
import { CookieStorage } from '@amplitude/analytics-client-common';
import { MemoryStorage } from '@amplitude/analytics-core';
import {
    type Storage,
    type CookieStorageOptions,
    type UserSession,
} from '@amplitude/analytics-types';

import { ApiKey, DefaultConfiguration } from './ampli';

const IS_PROD_ENV = process.env.NODE_ENV === 'production';
const environment = IS_PROD_ENV ? 'production' : 'development';
const apiKey = ApiKey[environment];

export async function initAmplitude(isWalletInitialized: () => boolean) {
    amplitude.init(apiKey, undefined, {
        ...DefaultConfiguration,
        logLevel: IS_PROD_ENV
            ? amplitude.Types.LogLevel.Warn
            : amplitude.Types.LogLevel.Debug,
        disableCookies: true,
        cookieStorage: new FlexibleCookieStorage(isWalletInitialized),
    });
}

export class FlexibleCookieStorage<T> implements Storage<T> {
    #memoryStorage: MemoryStorage<T>;
    #cookieStorage: CookieStorage<T>;
    #isWalletInitialized: () => boolean;

    constructor(isWalletInitialized: () => boolean) {
        this.#memoryStorage = new MemoryStorage<T>();
        this.#cookieStorage = new CookieStorage<T>();
        this.#isWalletInitialized = isWalletInitialized;
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
        const isInitialized = this.#isWalletInitialized();

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

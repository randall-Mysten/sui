/* tslint:disable */
/* eslint-disable */
/**
 * Ampli - A strong typed wrapper for your Analytics
 *
 * This file is generated by Amplitude.
 * To update run 'ampli pull web'
 *
 * Required dependencies: @amplitude/analytics-browser@^1.3.0
 * Tracking Plan Version: 1
 * Build: 1.0.0
 * Runtime: browser:typescript-ampli-v2
 *
 * [View Tracking Plan](https://data.amplitude.com/mystenlabs/Sui%20Explorer/events/main/latest)
 *
 * [Full Setup Instructions](https://data.amplitude.com/mystenlabs/Sui%20Explorer/implementation/web)
 */

import * as amplitude from '@amplitude/analytics-browser';

export type Environment = 'production' | 'development';

export const ApiKey: Record<Environment, string> = {
    production: '1c341785c734c98d9f2dca06128b914a',
    development: '94db6502f3853b6f35ccd070f6d37082',
};

/**
 * Default Amplitude configuration options. Contains tracking plan information.
 */
export const DefaultConfiguration: BrowserOptions = {
    plan: {
        version: '1',
        branch: 'main',
        source: 'web',
        versionId: 'e04b8300-7375-4e37-a47e-7eb097e55c65',
    },
    ...{
        ingestionMetadata: {
            sourceName: 'browser-typescript-ampli',
            sourceVersion: '2.0.0',
        },
    },
};

export interface LoadOptionsBase {
    disabled?: boolean;
}

export type LoadOptionsWithEnvironment = LoadOptionsBase & {
    environment: Environment;
    client?: { configuration?: BrowserOptions };
};
export type LoadOptionsWithApiKey = LoadOptionsBase & {
    client: { apiKey: string; configuration?: BrowserOptions };
};
export type LoadOptionsWithClientInstance = LoadOptionsBase & {
    client: { instance: BrowserClient };
};

export type LoadOptions =
    | LoadOptionsWithEnvironment
    | LoadOptionsWithApiKey
    | LoadOptionsWithClientInstance;

export type PromiseResult<T> = { promise: Promise<T | void> };

const getVoidPromiseResult = () => ({ promise: Promise.resolve() });

// prettier-ignore
export class Ampli {
  private disabled: boolean = false;
  private amplitude?: BrowserClient;

  get client(): BrowserClient {
    this.isInitializedAndEnabled();
    return this.amplitude!;
  }

  get isLoaded(): boolean {
    return this.amplitude != null;
  }

  private isInitializedAndEnabled(): boolean {
    if (!this.amplitude) {
      console.error('ERROR: Ampli is not yet initialized. Have you called ampli.load() on app start?');
      return false;
    }
    return !this.disabled;
  }

  /**
   * Initialize the Ampli SDK. Call once when your application starts.
   *
   * @param options Configuration options to initialize the Ampli SDK with.
   */
  load(options: LoadOptions): PromiseResult<void> {
    this.disabled = options.disabled ?? false;

    if (this.amplitude) {
      console.warn('WARNING: Ampli is already intialized. Ampli.load() should be called once at application startup.');
      return getVoidPromiseResult();
    }

    let apiKey: string | null = null;
    if (options.client && 'apiKey' in options.client) {
      apiKey = options.client.apiKey;
    } else if ('environment' in options) {
      apiKey = ApiKey[options.environment];
    }

    if (options.client && 'instance' in options.client) {
      this.amplitude = options.client.instance;
    } else if (apiKey) {
      this.amplitude = amplitude.createInstance();
      return this.amplitude.init(apiKey, undefined, { ...DefaultConfiguration, ...options.client?.configuration });
    } else {
      console.error("ERROR: ampli.load() requires 'environment', 'client.apiKey', or 'client.instance'");
    }

    return getVoidPromiseResult();
  }

  /**
   * Identify a user and set user properties.
   *
   * @param userId The user's id.
   * @param options Optional event options.
   */
  identify(
    userId: string | undefined,
    options?: EventOptions,
  ): PromiseResult<Result> {
    if (!this.isInitializedAndEnabled()) {
      return getVoidPromiseResult();
    }

    if (userId) {
      options = {...options,  user_id: userId};
    }

    const amplitudeIdentify = new amplitude.Identify();
    return this.amplitude!.identify(
      amplitudeIdentify,
      options,
    );
  }

  /**
   * Track event
   *
   * @param event The event to track.
   * @param options Optional event options.
   */
  track(event: Event, options?: EventOptions): PromiseResult<Result> {
    if (!this.isInitializedAndEnabled()) {
      return getVoidPromiseResult();
    }

    return this.amplitude!.track(event, undefined, options);
  }

}

export const ampli = new Ampli();

// BASE TYPES
type BrowserOptions = amplitude.Types.BrowserOptions;

export type BrowserClient = amplitude.Types.BrowserClient;
export type BaseEvent = amplitude.Types.BaseEvent;
export type IdentifyEvent = amplitude.Types.IdentifyEvent;
export type GroupEvent = amplitude.Types.GroupIdentifyEvent;
export type Event = amplitude.Types.Event;
export type EventOptions = amplitude.Types.EventOptions;
export type Result = amplitude.Types.Result;

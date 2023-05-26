// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import {
    useGetOwnedObjects,
    useGetOriginByteKioskContents,
} from '@mysten/core';
import {
    getObjectDisplay,
    type SuiObjectData,
    type SuiAddress,
    type SuiObjectResponse,
} from '@mysten/sui.js';

const hasDisplayData = (obj: SuiObjectResponse) => !!getObjectDisplay(obj).data;

export function useGetNFTs(address?: SuiAddress | null) {
    const {
        data,
        isLoading,
        error,
        isError,
        isFetchingNextPage,
        hasNextPage,
        fetchNextPage,
        isInitialLoading,
    } = useGetOwnedObjects(
        address,
        {
            MatchNone: [{ StructType: '0x2::coin::Coin' }],
        },
        50
    );
    const shouldFetchKioskContents = false;
    const { data: obKioskContents, isLoading: areKioskContentsLoading } =
        useGetOriginByteKioskContents(address, !shouldFetchKioskContents);

    const filteredKioskContents =
        obKioskContents
            ?.filter(hasDisplayData)
            .map(({ data }) => data as SuiObjectData) || [];

    const nfts = [
        ...filteredKioskContents,
        ...(data?.pages
            .flatMap((page) => page.data)
            .filter(hasDisplayData)
            .map(({ data }) => data as SuiObjectData) || []),
    ];
    return {
        data: nfts,
        isInitialLoading,
        hasNextPage,
        isFetchingNextPage,
        fetchNextPage,
        isLoading:
            isLoading || (shouldFetchKioskContents && areKioskContentsLoading),
        isError: isError,
        error,
    };
}

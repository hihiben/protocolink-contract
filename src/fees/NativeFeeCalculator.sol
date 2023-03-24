// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FeeBase} from './FeeBase.sol';
import {IFeeCalculator} from '../interfaces/IFeeCalculator.sol';

contract NativeFeeCalculator is IFeeCalculator, FeeBase {
    address private constant _NATIVE = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    constructor(address router, uint256 feeRate) FeeBase(router, feeRate) {}

    function getFees(bytes calldata data) external view returns (address[] memory, uint256[] memory) {
        address[] memory tokens = new address[](1);
        tokens[0] = _NATIVE;

        uint256[] memory fees = new uint256[](1);
        fees[0] = calculateFee(uint256(bytes32(data)));
        return (tokens, fees);
    }

    function getDataWithFee(bytes calldata data) external pure returns (bytes memory) {
        return data;
    }
}
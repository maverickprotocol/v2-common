// SPDX-License-Identifier: GPL-2.0-or-later
// As the copyright holder of this work, Ubiquity Labs retains
// the right to distribute, use, and modify this code under any license of
// their choosing, in addition to the terms of the GPL-v2 or later.
pragma solidity ^0.8.25;

interface IMaverickV2FactoryAdmin {
    /**
     * @notice Set the protocol fee ratio.
     * @param _protocolFeeRatioD3 The new protocol fee ratio to set in
     * 3-decimal units.
     */
    function setProtocolFeeRatio(uint8 _protocolFeeRatioD3) external;

    /**
     * @notice Set the protocol lending fee rate.
     * @param  _protocolLendingFeeRateD18 The new protocol lending fee rate to
     * set in 18-decimal units.
     */
    function setProtocolLendingFeeRate(uint256 _protocolLendingFeeRateD18) external;

    /**
     * @notice Set the protocol fee receiver address.  If protocol fee is
     * non-zero, user will be able to permissionlessly push protocol fee from a
     * given pool to this address.
     */
    function setProtocolFeeReceiver(address receiver) external;

    /**
     * @notice Renounce ownership of the contract.
     */
    function renounceOwnership() external;

    /**
     * @notice Transfer ownership of the contract to a new owner.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) external;
}

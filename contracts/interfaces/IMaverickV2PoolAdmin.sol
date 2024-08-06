// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

interface IMaverickV2PoolAdmin {
    enum AdminAction {
        SetProtocolFeeRatioD3,
        ClaimProtocolFeesA,
        ClaimProtocolFeesB,
        SetLendingFeeRateD18
    }

    event PoolProtocolFeeCollected(uint256 feeCollected, bool isTokenA);

    event PoolSetProtocolFeeRatio(uint256 protocolFeeRatioD3);

    event PoolSetLendingFeeRate(uint256 lendingFeeRateD18);

    /**
     * @notice Perform pool admin action; this function can only be called by
     * the pool factory contract.  When called by other callers, this function
     * will revert.
     * @param action Selector of admin action from AdminAction enum.
     * @param value Applicable for "setting" admin actions and is the new
     * value of the parameter being set.
     */
    function adminAction(AdminAction action, uint256 value) external;
}

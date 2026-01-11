// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IRebaseToken} from "./interfaces/IRebaseToken.sol";

contract Vault {
    // We need to pass the token address to the constructor
    // create a deposit function that mints tokens to the user equal to the aamount of ETH they sent
    // create a redeem function taht burns token form the user and sends the user ETH
    // create a way to add rewards to the vault
    error Vault__RedeemFailed();

    IRebaseToken immutable i_rebaseToken;

    event Deposit(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);

    constructor (IRebaseToken _rebaseToken) {
        i_rebaseToken = _rebaseToken;
    }

    /** 
     * @notice The contract will receive ether when another contract uses .call() or .transfer() to send ETH
     * @dev A fallback function for receiving Ether when another contract sends ETH with empty calldata is sent to the contract
     * @dev see docs.soliditylang.org
    * @dev Must be external and must be payable
    */

    receive() external payable {}

    /// @notice Allows users to deposit ETH into the vault and mint rebase tokens in return
    function deposit() external payable {
        // 1. we need to uset he amount of ETH the user has sent to mint tokens to the user
        i_rebaseToken.mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    /// @return - The address of the rebase token
    function getRebaseTokenAddress() external view returns (address) {
        return address(i_rebaseToken);
    }

    /// @notice Allows users to redeem their rebase tokens for ETH
    /// @param _amount The amonunt of rebase tokens to redeem
    function redeem(uint256 _amount) external {
        if (_amount == type(uint256).max) {
            _amount = i_rebaseToken.balanceOf(msg.sender);
        }
        // 1. burn the tokens from the user
        i_rebaseToken.burn(msg.sender, _amount);
        // 2. we need to send the user ETH
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        if (!success) {
            revert Vault__RedeemFailed();
        }
        emit Redeem(msg.sender, _amount);
    }
}
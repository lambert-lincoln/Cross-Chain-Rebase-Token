// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Rebase Token
/// @author Lambert Lincoln
/// @notice This is a cross-chain rebase token that incentivises users to deposit into a vault and gain interest in reward.
/// @notice The interest rate in the smart contract can only decrease
/// @notice Each user will have their own interest rate that is the global interest rate at the time of depositing
contract RebaseToken is ERC20 {

    /* Errors */

    error RebaseToken__InterestRateCanOnlyDecrease(uint256 oldInterestRate, uint256 newInterestRate);
    error RebaseToken__AmountMustBeMoreThanZero();

    /* State Variables */

    uint256 private PRECISION_FACTOR = 1e18;

    // % per second
    uint256 private s_interestRate = 5e10; // 5e-8 * 1e18
    mapping(address => uint256) private s_userInterestRate;
    mapping(address => uint256) private s_userLastUpdatedTimestamp;

    /* Events */
    event InterestRateSet(uint256 newInterestRate);

    constructor() ERC20("Rebase Token", "RBT") { }

    modifier moreThanZero(uint256 _amount) {
        if (_amount <= 0) {
            revert RebaseToken__AmountMustBeMoreThanZero();
        }
        _;
    }

    /// @notice Sets the new interest rate
    /// @dev The interest rate can only decrease
    /// @param _newInterestRate - A uint256 value of the new interest rate, account for the 18 decimals precision

    function setInterestRate(uint256 _newInterestRate) external {
        // Set the interest rate
        if (_newInterestRate >= _newInterestRate) {
            revert RebaseToken__InterestRateCanOnlyDecrease(s_interestRate, _newInterestRate);
        }
        s_interestRate = _newInterestRate;
        emit InterestRateSet(_newInterestRate);
    }

    /// @notice Calculate the interest that has accumulated since the last update
    /// @param _user - address of the user
    /// @return linearInterest uint256 accrued interest for that user

    function _calculateUserAccumulatedInterestSinceLastUpdate(address _user) internal view returns (uint256 linearInterest) {
        // this is going to be linear growth with time
        // 1. Calculate since the last update
        uint256 timeElapsed = block.timestamp - s_userLastUpdatedTimestamp[_user];
        // 2. Calculate the amount of linear growth
        linearInterest = PRECISION_FACTOR + (s_userInterestRate[_user] * timeElapsed); // 18 decimal precision

    }

    /// @notice Calculate the balance for the user including the interest that has acumulate since the last update
    /// @notice (principle balance) + accrued interest
    /// @param _user - Address of uesr
    /// @return - the balance of the uesr including the interest that has accumulated since the last update

    function balanceOf(address _user) public view virtual override returns (uint256) {
        // get the principle balance (the number of tokens that have actuall been minted to the user)
        // using super because this function is overriding the balanceOf method
        return (super.balanceOf(_user) * _calculateUserAccumulatedInterestSinceLastUpdate(_user) / PRECISION_FACTOR); // 36 decimal precision so need to divide by 1e18
        // eg.
        // deposit: 10 tokens
        // interest rate 0.5 tokens per second
        // time elapsed is 2 seconds
        // 10 + (10 * 0.5 * 2) <- principal amount * [1 + (user interest rate * time elapsed)]
    }

    /// @notice Transfer tokens from one user to another
    /// @param _recipient - Address of the user to transfer the tokens to
    /// @param _amount - Amount fo tokens to transfer
    /// @return - Whether the transfer was successful

    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender);
        }
        if (balanceOf(_recipient) == 0) {
            // recipient inherits sender's interest rate should the recipient not have a local interest rate
            s_userInterestRate[_recipient] = s_userInterestRate[msg.sender];
        }
        return super.transfer(_recipient, _amount);
    }

    /// @notice Transfer tokens from one user to another
    /// @param _recipient - Address of the user to transfer the tokens to
    /// @param _amount - Amount fo tokens to transfer
    /// @return - Whether the transfer was successful

    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        _mintAccruedInterest(_sender);
        _mintAccruedInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_sender);
        }
        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[_sender];
        }
        return super.transferFrom(_sender, _recipient, _amount);
    }

    /// @notice Mint the accured interest to the user since the last time they interacted with the protocol (eg. burn, mint, transfer)
    /// @param _user - address of the user
    function _mintAccruedInterest(address _user) internal {

        // (1). find their current balance of rebase tokens that have been minted to the user -> Principle balance
        uint256 previousPrincipleBalance = super.balanceOf(_user);

        // (2). calculate their current balance including any interest
        uint256 currentPrincipleBalance = balanceOf(_user);

        // (3). calculate the number of tokens that need to be minted to the user -> (2) - (1)
        uint256 balanceIncrease = currentPrincipleBalance - previousPrincipleBalance;
        
        // (4). set the users last updated timestamp
        s_userLastUpdatedTimestamp[_user] = block.timestamp;

        // (5). call _mint to mint the tokens to the user
        _mint(_user, balanceIncrease);

    }

    /// @notice Mint the user tokens when they deposit into the vault
    /// @param _to - Address of the user to mint the tokens to
    /// @param _amount - uint256 amount of tokens to mint

    function mint(address _to, uint256 _amount) external {
        _mintAccruedInterest(_to);
        s_userInterestRate[_to] = s_interestRate;
        _mint(_to, _amount);
    }

    /// @notice Burn tokens ONLY when user is redeeming their rewards and deposit
    /// @dev NOT FOR CROSS CHAIN TRANSACTION
    /// @param _from - The address of the user to burn the tokens from
    /// @param _amount - The amount of tokens to burn

    function burn(address _from, uint256 _amount) external {
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_from);
        }
        _mintAccruedInterest(_from);
        _burn(_from, _amount);
    }

    /* Getter Functions */

    /// @notice Get the interest rate for user
    /// @param _user - addres of user
    /// @return - a uint256 value of the new interest rate, account for the 18 decimals

    function getUserInterestRate(address _user) external view returns (uint256) {
        return s_userInterestRate[_user];
    }

}
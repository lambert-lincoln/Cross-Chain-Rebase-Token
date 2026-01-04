# Cross-chain Rebase Token

** A protcol that allows user to deposit into a vault and in return, receive rebase tokens that represent their underlying balance.**

## What are Rebase Tokens?

Rebase tokens are a particular kind of cryptocurrency that periodically (typically daily or multiple times a day) modifies its total supply (Arora).

## Features

1. Allows user to deposit into a vault and earn "interest".

2. Rebase token -> balanceOf function is dynamic to show the changing balance with time.

    - Balance increases linearly with time

    - Mint tokens to our users every time they perform an action (minting, burning,transferring, or bridging)

3. Interest Rate

    - Individually set an interesst rate for each user based on some global interest rate of the protcol at the time thne uesr deposits into the vault.

    - The global interest rate can only decrease to incentivise/reward early adopters.

    - Increase token adoption

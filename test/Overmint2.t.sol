// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Overmint2.sol";

contract Overmint2Test is Test {
    Overmint2 public overmint2;

    function setUp() public virtual {
        overmint2 = new Overmint2();
    }

    function testAttack() public {
        Minion minion = new Minion(overmint2);
        Attacker attacker = new Attacker(overmint2, minion);
        attacker.attack();
        bool success = attacker.success();

        assertEq(success, true);
    }
}

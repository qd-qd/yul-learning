// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// solidity<>yul operation mapping: https://docs.soliditylang.org/en/v0.8.16/yul.html#evm-dialect
contract YulBasic {
    /**
        for-loop in yul:
        for { <init_statement> } <stopping_condition> <logic_run_on_each_iteration>
        the init statement can be moved out of the loop but the curly braces need to stay
    */
    function isPrime(uint256 x) public pure returns (bool isXPrime) {
        isXPrime = true;

        assembly {
            let halfX := add(div(x, 1), 1)
            for {
                let i := 2
            } lt(i, halfX) {
                i := add(i, 1)
            } {
                if iszero(mod(x, i)) {
                    // set isXPrime to false
                    isXPrime := 0
                    break
                }
            }
        }
    }

    function isTruthy() external pure returns (uint256 result) {
        result = 2;

        assembly {
            if 2 {
                result := 1
            }
        }

        return result; // returns 1
    }

    function isFalsy() external pure returns (uint256 result) {
        result = 1;

        assembly {
            if 0 {
                result := 2
            }
        }

        return result; // returns 1
    }

    // good to know - the operator `not` apply the Bitwise NOT operation.
    // not(0x00000...0000) === 0xFFFF....FFFFFFF
    // this should not be used to know if a variable is not zero
    function negation() external pure returns (uint256 result) {
        result = 1;
        assembly {
            // iszero(0) = 0x0000....1 === 1 for uint256
            if iszero(0) {
                result := 2
            }
        }

        return result; // returns 2
    }

    function max(uint256 x, uint256 y) external pure returns (uint256 maximum) {
        // there is no "else" in YUL, you have to chain your "if"
        assembly {
            if lt(x, y) {
                maximum := y
            }
            if lt(y, x) {
                maximum := x
            }
        }

        return maximum;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
    In this file, we learnt:
        1. calldataload
        2. imitating function selectors
        3. switch statement
        4. YUL functions with arguments
        5. functions that return
        6. exit from a function without returning
        7. validating calldata
**/

contract CalldataDemo {
    fallback() external {
        assembly {
            let cd := calldataload(0) // always loads 32 bytes
            // d2178b0800000000000000000000000000000000000000000000000000000000
            let selector := shr(0xe0, cd) // shift right 224 bits to get last 4 bytes
            // 00000000000000000000000000000000000000000000000000000000d2178b08

            // unlike other languages, switch does not "fall through"
            // that means if one case is valid, it will not check the other cases
            switch selector
            case 0xd2178b08 {
                /* get2() */
                returnUint(2)
            }
            case 0xba88df04 {
                /* get99(uint256) */
                returnUint(getNotSoSecretValue())
            }
            default {
                revert(0, 0)
            }

            function getNotSoSecretValue() -> result {
                // if the calldata is lower than 36 bytes (32 bytes for the 1st arg + 4 bytes for the selector)
                // we revert the transaction
                if lt(calldatasize(), 36) {
                    revert(0, 0)
                }

                // we load the first argument by skipping the first 4 bytes as it is the function selector
                let arg1 := calldataload(4)
                // if the argument is equal to 8, we return 88 else we return 99
                if eq(arg1, 8) {
                    result := 88
                    // the keyword `leave` stops the execution of the function
                    leave
                }

                result := 99
            }

            function returnUint(value) {
                mstore(0, value)
                return(0, 0x20)
            }
        }
    }
}

interface ICalldataDemo {
    function get2() external view returns (uint256);

    function get99(uint256) external view returns (uint256);
}

contract CallDemo {
    ICalldataDemo public target;

    constructor(ICalldataDemo _a) {
        target = _a;
    }

    function callGet2() external view returns (uint256) {
        return target.get2();
    }

    function callGet99(uint256 arg) external view returns (uint256) {
        return target.get99(arg);
    }
}

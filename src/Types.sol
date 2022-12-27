// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract YulTypes {
    function getNumber() external pure returns (uint256) {
        uint256 x;

        assembly {
            // can reference variables from the outside
            x := 42
        }

        return x;
    }

    function getTen() external pure returns (uint256) {
        uint256 x;

        assembly {
            // 10 in hexa
            x := 0xa
        }

        return x;
    }

    function getText() external pure returns (string memory) {
        // string memory mystring;
        bytes32 myString = "";

        assembly {
            // we cannot assign directly a value to string type
            // this is a non-sense, because we try to assign the value "hello" to the pointer

            // as yul works with 32-bytes word, we can't assign value larger than 32 bytes
            myString := "hello"
        }

        return string(abi.encode(myString));
    }

    function representation() external pure returns (bool) {
        bool x;

        assembly {
            x := 1
        }

        // return true because the last bytbite of the bool is 1
        return x;
    }
}

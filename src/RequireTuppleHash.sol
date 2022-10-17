// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract YulRequireTuppleHash {
    // return/tupples
    function returnTupple() external pure returns (uint256, uint256) {
        assembly {
            // write each values of the tuple
            mstore(0x00, 2)
            mstore(0x20, 4)

            // return the value of the tuple by returning the beginning and the ending pointers
            return(0x00, 0x20)
        }
    }

    // require
    function requireInYul() external view returns (bytes32) {
        assembly {
            if iszero(
                eq(caller(), 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045)
            ) {
                revert(0, 0)
            }
        }
    }

    function hashInSolidity() external pure returns (bytes32) {
        bytes memory toBeHashed = abi.encode(1, 2, 3);
        return keccak256(toBeHashed);
    }

    // hash
    function hashInYul() external pure returns (bytes32) {
        assembly {
            let freeMemoryPointer := mload(0x40)

            // store 1, 2, 3 in memory
            mstore(freeMemoryPointer, 1)
            mstore(add(freeMemoryPointer, 0x20), 2)
            mstore(add(freeMemoryPointer, 0x40), 3)

            // update memory pointer
            mstore(0x40, add(freeMemoryPointer, 0x60))
            mstore(0x40, keccak256(freeMemoryPointer, 0x60))

            // return 32bytes
            return(0x00, 0x20)
        }
    }
}

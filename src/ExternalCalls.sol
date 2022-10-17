// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
    Transaction data can be arbitrary - only constrained by gas cost!

    This is the Solidity dominance that enforced a convention on how tx.data is used
    When sending ot a wallet, you don't put any data in unless you are trying to send that person a message 
    (hackers have used this field for taunts)

    When sending to a smart contract, the first four bytes specify which function you are calling,
    and the bytes that follow are abi encoded function arguments

    Solidity expects the bytes after the function selector to always be a multiple of 32 in length, 
    but this is convention!

    If you send more bytes, solidity will ignore them. But a YUL smart contract can be programmed to respond to
    arbitrary length tx.data in an arbitrary manner

    So, function selectors are the first four bytes of the keccack256 of the function signature

    Also, frontend apps know how to format the transaction based on the abi specification of the contract
    In solidity, the function selector and 32 byte encoded arguments are created under the hood, by 
    interfaces or if you use `abi.encodeWithSignature("functionName", arg1, arg2, ...)`

    But in YUL, you have to be explicit! It doesn't know about function selectors, interfaces, or abi encoding
    If you want to make an external call to a solidity contract, you must implement all of that yourself
*/

contract OtherContract {
    uint256 public x;

    uint256[] public arr;

    // "get21()"         -> "9a884bde"
    function get21() external pure returns (uint256) {
        return 21;
    }

    // "revertWith999()" -> "73712595"
    function revertWith999() external pure returns (uint256) {
        assembly {
            // store 999 in memory
            mstore(0x00, 999)
            // revert the value stored (0x20 == 32 bits == 1 word)
            revert(0x00, 0x20)
        }
    }

    function multiply(uint256 a, uint8 b) external pure returns (uint256) {
        return a + b;
    }

    // 4018d9aa
    function setX(uint256 _x) external {
        x = _x;
    }

    // 7c70b4db
    function variableReturnLength(uint256 len)
        external
        pure
        returns (bytes memory ret)
    {
        ret = new bytes(len);

        for (uint256 i; i < ret.length; i++) {
            ret[i] = 0xab;
        }

        return ret;
    }
}

contract YulExternalCalls {
    function externalViewCallNoArgs(address contractAddress)
        external
        view
        returns (uint256)
    {
        assembly {
            // We push the four-byte selector of the function we wanna call at the top of the stack
            // (`get21()` -> `9a884bde`)
            mstore(0x00, 0x9a884bde)
            // 000000000000000000000000000000000000000000000000000000009a884bde
            //                                                         |      |
            //                                                         28     32

            // staticcall revert if a change operates. As we in a view function, we use it
            // call is the alternative for external calls that can modify the state
            // first param: the gas, second param: the address of the contract, third/fourth param: the arguments
            // fifth param: the memory pointer where to store the result, sixth param: the size of the result
            let success := staticcall(
                gas(),
                contractAddress,
                28,
                32,
                0x00,
                0x20
            )

            if iszero(success) {
                revert(0, 0)
            }

            // we return the data returned by the staticcall
            return(0x00, 0x20)
        }
    }

    function getViaRevert(address contractAddress)
        external
        view
        returns (uint256)
    {
        assembly {
            // we push the four-byte selector of the function we wanna call at the top of the stack
            // ("revertWith999()" -> "73712595")
            mstore(0x00, 0x73712595)

            // using `pop` we can return a function that revert
            pop(staticcall(gas(), contractAddress, 28, 32, 0x00, 0x20))
            return(0x00, 0x20)
        }
    }

    function callMultiply(address contractAddress)
        external
        view
        returns (uint256 result)
    {
        assembly {
            let memoryPointer := mload(0x40)
            let oldMemoryPointer := memoryPointer

            // "multiply(uint256,uint256)" -> "196e6d84"
            mstore(memoryPointer, 0x196e6d84)
            mstore(add(memoryPointer, 0x20), 3)
            mstore(add(memoryPointer, 0x40), 11)
            // why ?
            mstore(0x40, add(memoryPointer, 0x60)) // advance the memory pointer by 3 x 32bytes

            //  0000000000000000000000000000000000000000000000000000000196e6d84
            //  000000000000000000000000000000000000000000000000000000000000003
            //  00000000000000000000000000000000000000000000000000000000000000b

            let success := staticcall(
                gas(),
                contractAddress,
                // 28 because 28*2=56, because we only want the last 4-bytes selector of the function
                add(oldMemoryPointer, 28),
                mload(0x40),
                0x00,
                0x20
            )

            if iszero(success) {
                revert(0, 0)
            }

            result := mload(0x00)
        }
    }

    function externalStateChangingCall(address contractAddress)
        external
        payable
    {
        assembly {
            mstore(0x00, 0x4018d9aa)
            mstore(0x20, 999)

            // callvalue is the msg.value passe when calling this method
            let success := call(
                gas(),
                contractAddress,
                callvalue(),
                28,
                add(28, 32),
                0x00,
                0x00
            )
            if iszero(success) {
                revert(0, 0)
            }
        }
    }

    function unknownReturnSize(address contractAddress, uint256 amount)
        external
        view
        returns (bytes32)
    {
        assembly {
            mstore(0x00, 0x7c70b4db)
            mstore(0x20, amount)

            let success := staticcall(
                gas(),
                contractAddress,
                28,
                add(28, 32),
                0x00,
                0x00
            )

            if iszero(success) {
                revert(0, 0)
            }

            // returndatacopy(destoffset, offset, size)
            returndatacopy(0, 0, returndatasize())
            return(0, returndatasize())
        }
    }
}

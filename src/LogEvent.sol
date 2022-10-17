// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract YulLogsEvents {
    event SomeLog(uint256 indexed a, uint256 indexed b);
    event SomeLogV2(uint256 indexed a, bool);

    function EmitLog() external {
        emit SomeLog(1, 2);
    }

    function EmitLogYul() external {
        assembly {
            // keccack256("SomeLog(uint256,uint256)")
            let
                signature
            := 0xc200138117cf199dd335a2c6079a6e1be01e6592b6a76d4b5fc31b169df819cc
            log3(0, 0, signature, 1, 2)
        }
    }

    function EmitLogV2() external {
        emit SomeLogV2(1, true);
    }

    function EmitLogV2Yul() external {
        assembly {
            // keccack256("SomeLog(uint256,uint256)")
            let
                signature
            := 0x113cea0e4d6903d772af04edb841b17a164bff0f0d88609aedd1c4ac9b0c15c2

            // we push the value 1, equivalent to true, to the stack
            mstore(0x00, 1)

            // we load the value 1 from the stack by passing the size of the value as second param
            log2(0, 0x20, signature, 5)
        }
    }
}

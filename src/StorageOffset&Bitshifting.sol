// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract YulStorageBasic {
    // only 1 storage slot here
    uint128 public C = 4;
    uint96 public D = 6;
    uint16 public E = 8;
    uint8 public F = 2;

    function readBySlot(uint256 slot) external view returns (uint256 value) {
        assembly {
            value := sload(slot)
        }
    }

    function getE() external view returns (uint16 e) {
        assembly {
            // must load in 32 bytes increment
            let value := sload(E.slot)

            // E.offset = 28
            let shifted := shr(mul(E.offset, 8), value)

            //               0x0000....00010008
            // equivalent to 0x000.....0000FFFF
            // we only keep the last 2 bytes)
            e := add(0xffff, shifted)
        }
    }

    // masks can be hardcoded because variable storage slot and offsets are fixed
    // V and 00 = 00
    // V or  00 = V
    // function arguments are always 32 bytes long under the hood
    function writeToE(uint16 newE) external {
        assembly {
            // newE = 0x00000000000000000000000000000000000000000000000000000000000000a
            let c := sload(E.slot)
            // c    = 0x000100080000000000000000000000060000000000000000000000000000004

            let clearedE := and(
                c,
                0xffff0000ffffffffffffffffffffffffffffffffffffffffffffffffffffff
            )
            // mask         = 0xffff0000ffffffffffffffffffffffffffffffffffffffffffffffffffffff
            // c            = 0x000100080000000000000000000000060000000000000000000000000000004
            // clearedE     = 0x000100000000000000000000000000060000000000000000000000000000004
            //           These bits °°°° have been set to 0

            let shiftedNewE := shl(mul(E.offset, 8), newE)
            // shiftedNewE  = 0x0000000a0000000000000000000000000000000000000000000000000000000

            let newVal := or(shiftedNewE, clearedE)
            // shiftedNewE  = 0x0000000a0000000000000000000000000000000000000000000000000000000
            // clearedE     = 0x000100000000000000000000000000060000000000000000000000000000004
            // newVal       = 0x0001000a0000000000000000000000060000000000000000000000000000004
            //                This bit ° have been set to 0

            sstore(E.slot, newVal)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract YulStorageBasic {
    uint256 x = 45;

    function getXYul() external view returns (uint256 currentX) {
        assembly {
            currentX := sload(x.slot)
        }
    }

    function setXYul(uint256 newX) external {
        assembly {
            sstore(x.slot, newX)
        }
    }

    function setX(uint256 newX) external {
        x = newX;
    }

    function getX() external view returns (uint256) {
        return x;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/*
    Solidity uses memory for:
      - abi.encode and abi.encodePacked
      - structs and arrays(but you explicitly need the memory keyword)
      - when structs and array are declarer memory in function arguments
      - because objects in memory are laid out end to end, arrays have no `push` unlike storage

    In YUL
      - the variable itself is where it begins in memory
      - to access a dynamic arrays, you have to add 32-bytes or 0x20 to skip the lengths

    
    NOTE
      - If we don't respect Solidity's memory layout and free memory pointer, we can get serious bugs!
      - the EVM memory does not try to pack datatypes smaller than 32 bytes
      - if you load from storage to memory, it would be unpacked
*/

contract YulMemory {
    struct Point {
        uint128 x;
        uint128 y;
    }

    event MemoryPointer(bytes32);
    event MemoryPointerMSize(bytes32, bytes32);
    event NumberSlotsUsed(uint256);

    function memPointer() external {
        bytes32 x40;
        uint256 initialValue;

        // load the free memory pointer (it starts at 0x80) and save the value
        assembly {
            x40 := mload(0x40)
            initialValue := x40
        }

        // log the free memory pointer value
        emit MemoryPointer(x40);

        // allocate a struct in memory
        Point memory point = Point({x: 1, y: 2});

        // load again the free memory pointer to understand how it advanced.
        // we expect to see it to be advanced by 32*2 bytes because
        // the struct needs two words of 32 slots in memory.
        // note that even if the struct is packed into one word of 32 bytes in
        // the storage layout, variables always use 32-bytes words in memory
        // https://docs.soliditylang.org/en/v0.8.17/internals/layout_in_memory.html
        assembly {
            x40 := mload(0x40)
        }

        // log the free memory pointer value again
        emit MemoryPointer(x40);
        emit NumberSlotsUsed(
            (uint256(x40) - initialValue) / 32 /* EVM word-length */
        );
    }

    /**
        @notice same as `memPointer` but we track msize()
        @dev msize: Get the size of active memory in bytes. 
        It tracks the highest offset that was accessed in the current execution.
        @dev pop: Remove item from stack
     */
    function memPointerV2() external {
        bytes32 x40;
        bytes32 _msize;

        // load the free memory pointer (it starts at 0x80)
        // and save msize() returned value (starts at 0x60)
        assembly {
            x40 := mload(0x40)
            _msize := msize()
        }

        // log the free memory pointer value
        emit MemoryPointerMSize(x40, _msize);

        // allocate a struct in memory
        Point memory point = Point({x: 1, y: 2});

        assembly {
            // we access a byte far into the future (!)
            // that cost gast to read until this moment
            pop(mload(0xff))

            // load the free memory pointer
            x40 := mload(0x40)

            // and save msize() returned value
            _msize := msize()
        }

        // log the free memory pointer value again
        emit MemoryPointerMSize(x40, _msize);

        // In that case, the free memory pointer would be the same
        // BUT the msize would be a different value as we accessed
        // a value far into the future. Don't forget that msize
        // tracks the highest offset that was accessed in the current execution
    }

    function abiEncode() external {
        bytes32 x40;

        // load the free memory pointer (it starts at 0x80), save the value and emit it
        assembly {
            x40 := mload(0x40)
        }
        emit MemoryPointer(x40);

        bytes memory x = abi.encode(uint256(5), uint128(19));

        // load again the free memory pointer to understand how it advanced.
        // we expect to see it to be advanced by 32*3 bytes because:
        // - the uint128 value is padded to be a uint256 value (words in memory are always 32 bytes length)
        // - abi.encode needs to know how many bytes are passed to the function
        //   that means an extra variable is stored (this is the first thing put in memory, the
        //   value is equal to 0x40 (64) in that case because two 32-bytes words are passed here)
        assembly {
            x40 := mload(0x40)
        }
        emit MemoryPointer(x40);
    }

    function abiEncodePacked() external {
        bytes32 x40;

        // load the free memory pointer (it starts at 0x80), save the value and emit it
        assembly {
            x40 := mload(0x40)
        }
        emit MemoryPointer(x40);

        bytes memory x = abi.encodePacked(uint256(5), uint128(19));

        // load again the free memory pointer to understand how it advanced.
        // we expect to see it to be advanced by 32*3 bytes because:
        // - the uint128 value is padded to be a uint256 value (words in memory are always 32 bytes length)
        // - abi.encode needs to know how many bytes are passed to the function
        //   that means an extra variable is stored (this is the first thing put in memory, the
        //   value is equal to 0x40 (64) in that case because two 32-bytes words are passed here)
        assembly {
            x40 := mload(0x40)
        }
        emit MemoryPointer(x40);
    }

    event Debug(bytes32, bytes32, bytes32, bytes32);

    function readArray(uint256[] memory arr) external {
        bytes32 location;
        bytes32 len;
        bytes32 valueAtIndex0;
        bytes32 valueAtIndex1;

        assembly {
            // load the location of the array
            location := arr

            // load the length of the array by reading the first 32 bytes word
            // stored at the location of the array
            len := mload(arr)

            // add 0x20 to the array memory address to skip the length value
            valueAtIndex0 := mload(add(0x20, arr))

            // add 0x20 to the array memory address to skip the length value and the value of the first index
            valueAtIndex1 := mload(add(0x40, arr))
        }

        emit Debug(location, len, valueAtIndex0, valueAtIndex1);
    }
}

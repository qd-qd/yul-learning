// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract YulStorageComplex {
    uint256[3] fixedArray;
    uint256[] bigArray;
    uint8[] smallArray;

    mapping(uint256 => uint256) public myMapping;
    mapping(uint256 => mapping(uint256 => uint256)) public nestedMapping;
    mapping(uint256 => mapping(string => uint256)) public nestedMappingString;
    mapping(address => uint256[]) public addressToList;

    constructor() {
        fixedArray = [99, 999, 9999];
        bigArray = [10, 20, 30, 40];
        smallArray = [1, 2, 3];

        myMapping[10] = 5;
        myMapping[11] = 6;
        nestedMapping[2][4] = 7;
        nestedMappingString[1]["toto"] = 12;

        addressToList[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = [
            42,
            1337,
            777
        ];
    }

    // @dev to access a length of an array, we load the slot of the array
    function bigArraylength() external view returns (uint256 value) {
        assembly {
            value := sload(bigArray.slot)
        }
    }

    /// @notice read the `fixedArray` array
    function readValueFromFixedArray(uint256 index)
        external
        view
        returns (uint256 value)
    {
        uint256 slot;

        assembly {
            // first we get the slot of the fixed array
            slot := fixedArray.slot

            // finally we load the value from the addition of the slot and the index
            value := sload(add(slot, index))
        }
    }

    /// @notice read the `bigArray` array
    function readValueFromDynamicArray(uint256 index)
        external
        view
        returns (uint256 value)
    {
        uint256 slot;

        // first we get the slot of the non-fixed array
        assembly {
            slot := bigArray.slot
        }

        // then we encode it and keccak the value returned (FOR DYNAMIC ARRAY !)
        bytes32 location = keccak256(abi.encode(slot));

        // finally we load the value from the addition of the location and the index
        assembly {
            value := sload(add(location, index))
        }
    }

    function getMapping(uint256 key) external view returns (uint256 value) {
        uint256 slot;

        // first we get the slot of the non-fixed array
        assembly {
            slot := myMapping.slot
        }

        // then we encode the key and the slot casted in the uint256
        // type using keccak
        bytes32 location = keccak256(abi.encode(key, uint256(slot)));

        // finally we just load the location
        assembly {
            value := sload(location)
        }
    }

    function getNestedMapping(
        uint256 x, // the first value in the mapping (2)
        uint256 y // the second value in the mapping (4)
    ) external view returns (uint256 value) {
        uint256 slot;

        // first we get the slot of the mapping
        assembly {
            slot := nestedMapping.slot
        }

        /*  
            We try to load the location of the value nestedMapping[2][4]
            - We start by access the value of nestedMapping[2] by encoding
            the value of x (2) with the .
            - Then we access the value of nestedMapping[2][4] by encoding
            the output of the first step with y (4).
            - Finally we keccak the value returned by the second step
        */
        bytes32 location = keccak256(
            abi.encode(y, keccak256(abi.encode(x, uint256(slot))))
        );

        // finally we just load the location
        assembly {
            value := sload(location)
        }
    }

    // FIXME: uint => (string => uint) mapping
    function getNestedMapping(
        uint256 x, // the first value in the mapping (1)
        string calldata y // the second value in the mapping ('toto')
    ) external view returns (uint256 value) {
        uint256 slot;

        // first we get the slot of the mapping
        assembly {
            slot := nestedMappingString.slot
        }

        /*  
            We try to load the location of the value nestedMappingString[1]['toto']
            - We start by access the value of nestedMappingString[1] by encoding
            the value of x (2) with the .
            - Then we access the value of nestedMappingString[1]['toto'] by encoding
            the output of the first step with y ('toto').
            - Finally we keccak the value returned by the second step
        */
        bytes32 location = keccak256(
            abi.encode(y, keccak256(abi.encode(x, uint256(slot))))
        );

        // finally we just load the location
        assembly {
            value := sload(location)
        }
    }

    function getAddressToList(
        uint256 index,
        address addr /* 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4 */
    ) external view returns (uint256 value) {
        uint256 slot;

        // first we get the slot of the mapping
        assembly {
            slot := addressToList.slot
        }

        /*  
            We try to load the location of the value addressToList[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] 
            - We start by encoding the address and the slot
            - Then we hash the encoded value, we encode the hashed value and we hash it again

            At this step, we have the location of the array saved in the mapping
        */
        bytes32 location = keccak256(
            abi.encode(keccak256(abi.encode(address(addr), uint256(slot))))
        );

        // finally we load the value from the addition of the location and the index
        assembly {
            value := sload(add(location, index))
        }
    }
}

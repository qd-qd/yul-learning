// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// In this file, we will analyze the shape of the calldata for multiple functions that include dynamic
// length arguments. We will run the transaction then copy the calldata and format it to separate words
contract YulWithDraw {
    constructor() payable {}

    address public constant owner = 0xd1699002d9548DCA840268ba1bd1afa27E0ba62d;

    function withdraw() external {
        (bool success, ) = payable(owner).call{value: address(this).balance}(
            ""
        );
        require(success);
    }

    function withdrawYul() external {
        assembly {
            // selfbalance: Get balance of currently executing account
            /**
                detailled `call` opcode:
                1. gas: amount of gas to send to the sub context to execute. The gas that is not used by the sub context is returned to this one.
                2. address: the account which context to execute.
                3. value: value in wei to send to the account.
                4. argsOffset: byte offset in the memory in bytes, the calldata of the sub context.
                5. argsSize: byte size to copy (size of the calldata).
                6. retOffset: byte offset in the memory in bytes, where to store the return data of the sub context.
                7. retSize: byte size to copy (size of the return data).
             */
            let success := call(gas(), owner, selfbalance(), 0, 0, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }
        }
    }

    function withdrawUsingTransferYul() external {
        assembly {
            // this is the Yul version of `payable(owner).transfer(address(this).balance)`
            let success := call(2300, owner, selfbalance(), 0, 0, 0, 0)

            // that's it. the `transfer` method override the gas value to 2300
            if iszero(success) {
                revert(0, 0)
            }
        }
    }

    /**
    note: the assembly code do the same as the one in the classic Solidity function. However:
    - During the deployment the assembly code is more light because we deploy less code to the EVM (we save ~84 bytes, that is ~13k gas)
    - On call, the difference in term of gas isn't very significant (we save ~80 gas)
    */
}

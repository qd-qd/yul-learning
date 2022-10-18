// SPDX-License-Identifier: MIT

/**
    In this file, we learnt:
        1. how to write `constructor` in YUL
        2. that YUL doesn't have to respect call data
        3. how to compile YUL (need to change the compiler)
        4. how to interact with YUL 
        5. custom code in the constructor


    One of the major issue of writing a contract in YUL exclusively is that the 
    contract won't be verifiable on Etherscan as YUL isn't an option there (!)

    Good usecase for 100% YUL
    1. deploying lots of small contracts that are easy to read in bytecode form
    2. doing arbitrage or MEV

    Base usecase
    1. needs to be verified
    2. medium or larger size
**/

object "Simple" {
    // constructor
    code {
        // deploy the contract
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return (0, datasize("runtime"))
    }

    // block of code that will be executed when the contract is called
    object "runtime" {
        code {
            mstore(0x00, 2)
            return (0x00, 0x20)
        }

        // storing data in contract bytecode
        data "Message" "Lorem Ipsum dolor"
    }g
}

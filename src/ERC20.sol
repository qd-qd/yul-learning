object "Token" {
    // constructor, called on deployment
    code {
        // Store the creator in slot zero.
        sstore(0, caller())

        // Deploy the contract
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return(0, datasize("runtime"))
    }

    // block of code that will be executed when the contract is called
    object "runtime" {
        code {
            // Protection against sending Ether
            require(iszero(callvalue()))

            // Dispatcher
            switch selector()
            case 0x70a08231 /* "balanceOf(address)" */ {
                returnUint(balanceOf(decodeAsAddress(0)))
            }
            case 0x18160ddd /* "totalSupply()" */ {
                returnUint(totalSupply())
            }
            case 0xa9059cbb /* "transfer(address,uint256)" */ {
                transfer(decodeAsAddress(0), decodeAsUint(1))
                returnTrue()
            }
            case 0x23b872dd /* "transferFrom(address,address,uint256)" */ {
                transferFrom(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2))
                returnTrue()
            }
            case 0x095ea7b3 /* "approve(address,uint256)" */ {
                approve(decodeAsAddress(0), decodeAsUint(1))
                returnTrue()
            }
            case 0xdd62ed3e /* "allowance(address,address)" */ {
                returnUint(allowance(decodeAsAddress(0), decodeAsAddress(1)))
            }
            case 0x40c10f19 /* "mint(address,uint256)" */ {
                mint(decodeAsAddress(0), decodeAsUint(1))
                returnTrue()
            }
            default {
                revert(0, 0)
            }

            function mint(account, amount) {
                require(calledByOwner())

                mintTokens(amount)
                addToBalance(account, amount)
                emitTransfer(0, account, amount)
            }
            function transfer(to, amount) {
                executeTransfer(caller(), to, amount)
            }
            function approve(spender, amount) {
                revertIfZeroAddress(spender)
                setAllowance(caller(), spender, amount)
                emitApproval(caller(), spender, amount)
            }
            function transferFrom(from, to, amount) {
                decreaseAllowanceBy(from, caller(), amount)
                executeTransfer(from, to, amount)
            }

            function executeTransfer(from, to, amount) {
                revertIfZeroAddress(to)
                deductFromBalance(from, amount)
                addToBalance(to, amount)
                emitTransfer(from, to, amount)
            }


            /* ---------- calldata decoding functions ----------- */
            function selector() -> s {
                s := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
            }

            function decodeAsAddress(offset) -> v {
                // getting 32 bytes from the argument index (represents the argument)
                v := decodeAsUint(offset)
                
                // 0xffffffffffffffffffffffffffffffffffffffff is only 20bytes, that means there is implicitely 
                // a 12 extra leading bytes of 0s (to fullfil the 32bytes word)
                // this line check if the address starts with 12 bytes of 0, if not, it's not a valid address, that's why we revert
                // note: address is a 20bytes type in Solidity, that means 12 first bytes must be full of 0 to be valid
                if iszero(iszero(and(v, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
                    revert(0, 0)
                }
            }
            function decodeAsUint(offset) -> v {
                // we skip over the 4 first bytes (fn selector) then load the argument (36-4=32 other bytes)
                let pos := add(4, mul(offset, 0x20))

                // check if the calldata contains at least 36 bytes (4 bytes for fn selector + 32 bytes for argument)
                // to be sure there is enough argument to load
                if lt(calldatasize(), add(pos, 0x20)) {
                    revert(0, 0)
                }
                // return the argument (32 bytes)
                v := calldataload(pos)
            }
            /* ---------- calldata encoding functions ---------- */
            function returnUint(v) {
                mstore(0, v)
                return(0, 0x20)
            }
            function returnTrue() {
                returnUint(1)
            }

            /* -------- events ---------- */
            function emitTransfer(from, to, amount) {
                // keccack256("Transfer(address,address,uint256)") [event defined in the spec]
                let signatureHash := 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
                emitEvent(signatureHash, from, to, amount)
            }
            function emitApproval(from, spender, amount) {
                // keccack256("Approval(address,address,uint256)") [event defined in the spec]
                let signatureHash := 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925
                emitEvent(signatureHash, from, spender, amount)
            }
            function emitEvent(signatureHash, indexed1, indexed2, nonIndexed) {
                mstore(0, nonIndexed)
                log3(0, 0x20, signatureHash, indexed1, indexed2)
            }

            /* -------- storage layout ---------- */
            // note: there is no way to name storage variables, that's why we use function
            // (that would be inlined) in that case.
            function ownerPos() -> p { p := 0 }
            // return the slot#1 inside of the storage layout
            function totalSupplyPos() -> p { p := 1 }
            // note: under the hood when we have a regular hash map (mapping(address => uint256)), this is going to be stored
            // in the keccack256 of the address and the slot of the storage variable.
            // However as we don't need to respect Solidity conventions in YUL, we can do whatever we want.
            // That's why in this case we use the address as it is already the hash of someone's public key, 
            // it's going to be random and not collide. The offset addded ensure it will not collide with the other storage variables.
            function accountToStorageOffset(account) -> offset {
                offset := add(0x1000, account)
            }
            // In solidity, a double mapping is stored using the hash of the concatenation of the storage slot and the keys.
            // In YUL we don't have to follow this convention, that's why here we use the offset returned by `accountToStorageOffset` and
            // the spender address.
            // In fact, as it is the only place in the code where we combine two addresses, we can keccack256 both addresses and use the result
            function allowanceStorageOffset(account, spender) -> offset {
                offset := accountToStorageOffset(account)
                mstore(0, offset)
                mstore(0x20, spender)
                // 0x40 = 64 bytes, it is the sum of both of the two memory words we just defined
                offset := keccak256(0, 0x40)
            }

            /* -------- storage access ---------- */
            function owner() -> o {
                o := sload(ownerPos())
            }
            function totalSupply() -> supply {
                supply := sload(totalSupplyPos())
            }
            function mintTokens(amount) {
                sstore(totalSupplyPos(), safeAdd(totalSupply(), amount))
            }
            function balanceOf(account) -> bal {
                bal := sload(accountToStorageOffset(account))
            }
            function addToBalance(account, amount) {
                let offset := accountToStorageOffset(account)
                sstore(offset, safeAdd(sload(offset), amount))
            }
            function deductFromBalance(account, amount) {
                let offset := accountToStorageOffset(account)
                let bal := sload(offset)
                // ensure the owner has enough balance
                require(lte(amount, bal))
                // underflow check isn't needed as we already checked the balance is enough
                sstore(offset, sub(bal, amount))
            }
            function allowance(account, spender) -> amount {
                amount := sload(allowanceStorageOffset(account, spender))
            }
            function setAllowance(account, spender, amount) {
                sstore(allowanceStorageOffset(account, spender), amount)
            }
            function decreaseAllowanceBy(account, spender, amount) {
                let offset := allowanceStorageOffset(account, spender)
                let currentAllowance := sload(offset)
                require(lte(amount, currentAllowance))
                sstore(offset, sub(currentAllowance, amount))
            }

            /* ---------- utility functions ---------- */
            function lte(a, b) -> r {
                r := iszero(gt(a, b))
            }
            function gte(a, b) -> r {
                r := iszero(lt(a, b))
            }
            // this function makes sure the result of the addition is not overflowing
            function safeAdd(a, b) -> r {
                r := add(a, b)
                // if the result is less than a or b, it means there was an overflow, we revert
                if or(lt(r, a), lt(r, b)) { revert(0, 0) }
            }
            function calledByOwner() -> cbo {
                cbo := eq(owner(), caller())
            }
            function revertIfZeroAddress(addr) {
                require(addr)
            }
            function require(condition) {
                if iszero(condition) { revert(0, 0) }
            }
        }
    }
}

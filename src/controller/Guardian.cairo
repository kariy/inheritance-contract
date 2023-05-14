// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import (
    get_tx_info,
    get_block_number,
    get_caller_address,
    get_contract_address,
)
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_secp.bigint import BigInt3
from starkware.cairo.common.cairo_secp.ec import EcPoint

@contract_interface
namespace ICartridgeAccount {
    func executeOnPlugin(plugin: felt, selector: felt, calldata_len: felt, calldata: felt*) -> (
        retdata_len: felt, retdata: felt*
    ) {
    }
}

@contract_interface
namespace ICartridgeControllerPlugin {
    func execute_inheritance(
        inheritor: felt, new_device_key: felt, new_admin_key: felt, from_block: felt
    ) {
    }
}

//
// Constructor
//

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    return ();
}

@external
func execute_inheritance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    inheritor: felt, new_device_key: felt, new_admin_key: felt, from_block: felt
) {
    // LOGIC FOR CHECKING THAT THE CALLER IS IN THE SISMO GROUP SHOULD BE HERE //

    let (calldata) = alloc();

    assert calldata[0] = inheritor;
    assert calldata[1] = new_device_key;
    assert calldata[2] = new_admin_key;
    assert calldata[3] = from_block;

    let CONTROLLER_PLUGIN_CLASS_HASH = 0x11bc105f30a91e8b17751b7f662dc72989ce84792d8a0b54140cd36940bda;
    let ACCOUNT_CONTRACT_ADDRESS = 0xdead;
    let EXECUTE_INHERITANCE_SELECTOR = 0x21bba08d3f20f2bdf6d3785392a445f8fe1668aff712a64d065971c104a690f;

    let (retdata_len, retdata) = ICartridgeAccount.executeOnPlugin(
        ACCOUNT_CONTRACT_ADDRESS,
        CONTROLLER_PLUGIN_CLASS_HASH,
        EXECUTE_INHERITANCE_SELECTOR,
        4,
        calldata,
    );

    return ();
}

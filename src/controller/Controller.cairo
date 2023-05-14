// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import (
    get_tx_info,
    get_contract_address,
    get_caller_address,
    get_block_number,
    get_block_timestamp,
)
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_secp.bigint import BigInt3
from starkware.cairo.common.cairo_secp.ec import EcPoint

from src.controller.library import Controller

@contract_interface
namespace IStarknetFactsRegistry {
    func get_verified_account_nonce(account: felt, block: felt) -> (nonce: felt) {
    }
}

struct CallArray {
    to: felt,
    selector: felt,
    data_offset: felt,
    data_len: felt,
}

@event
func controller_init(account: felt, admin_key: EcPoint, device_key: felt) {
}

@event
func controller_add_device_key(device_key: felt) {
}

@event
func controller_remove_device_key(device_key: felt) {
}

//
// Storage variables
//

@storage_var
func l2_starknet_facts_registry_contract() -> (res: felt) {
}

@storage_var
func inactivity_period() -> (res: felt) {
}

@storage_var
func controller_guardian_address() -> (res: felt) {
}

@external
func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    plugin_data_len: felt, plugin_data: felt*
) {
    with_attr error_message("Controller: invalid initilize data") {
        assert plugin_data_len = 7;
    }

    let admin_key = EcPoint(
        BigInt3(plugin_data[0], plugin_data[1], plugin_data[2]),
        BigInt3(plugin_data[3], plugin_data[4], plugin_data[5]),
    );
    Controller.initializer(admin_key, plugin_data[6]);

    let (self) = get_contract_address();
    controller_init.emit(self, admin_key, plugin_data[6]);

    inactivity_period.write(5);  // 5 seconds
    l2_starknet_facts_registry_contract.write(0x80085);

    return ();
}

@external
func execute_inheritance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    inheritor: felt, new_device_key: felt, new_admin_key: felt, from_block: felt
) {
    let (caller) = get_caller_address();
    let (guardian_address) = controller_guardian_address.read();

    with_attr error_message("Controller: only guardian can execute inheritance") {
        assert caller = guardian_address;
    }

    // get user nonce
    // get latest committed block (now - 1)
    check_user_nonce_hasnt_changed(from_block);

    // set new device key

    return ();
}

func check_user_nonce_hasnt_changed{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(from_block: felt) {
    let (latest_block_num) = get_block_number();
    let (latest_timestamp) = get_block_timestamp();

    // calculate block timestamp difference
    with_attr error_message("Controller: block timestamp difference is too small") {
        let block_diff = latest_block_num - from_block;
        let from_timestamp = block_diff * 60;  // we assume that every block is 1 minute apart
        assert is_le(from_timestamp, latest_timestamp) = 1;
    }

    let (facts_registry) = l2_starknet_facts_registry_contract.read();
    let (contract_address) = get_contract_address();

    let (nonce_before) = IStarknetFactsRegistry.get_verified_account_nonce(
        facts_registry, contract_address, from_block
    );

    let (nonce_latest) = IStarknetFactsRegistry.get_verified_account_nonce(
        facts_registry, contract_address, latest_block_num - 1
    );

    with_attr error_message("Controller: user nonce has changed in the specified period") {
        assert nonce_before = nonce_latest;
    }

    return ();
}

//
// Getters
//

@view
func is_public_key{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    public_key: felt
) -> (res: felt) {
    let (res) = Controller.is_public_key(public_key);
    return (res=res);
}

//
// Setters
//

@external
func add_device_key{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_device_key: felt
) {
    Controller.add_device_key(new_device_key);
    controller_add_device_key.emit(new_device_key);
    return ();
}

@external
func remove_device_key{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    device_key: felt
) {
    Controller.remove_device_key(device_key);
    controller_remove_device_key.emit(device_key);
    return ();
}

//
// Business logic
//

@view
func is_valid_signature{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
    ecdsa_ptr: SignatureBuiltin*,
    bitwise_ptr: BitwiseBuiltin*,
}(hash: felt, signature_len: felt, signature: felt*) -> (is_valid: felt) {
    let (is_valid) = Controller.is_valid_signature(hash, signature_len - 1, signature + 1);
    return (is_valid=is_valid);
}

@external
func validate{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
    ecdsa_ptr: SignatureBuiltin*,
    bitwise_ptr: BitwiseBuiltin*,
}(call_array_len: felt, call_array: CallArray*, calldata_len: felt, calldata: felt*) {
    let (tx_info) = get_tx_info();
    is_valid_signature(tx_info.transaction_hash, tx_info.signature_len, tx_info.signature);
    return ();
}

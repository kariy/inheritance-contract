%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin

// @notice This is a contract mocking the Herodotus Facts Registry contract.

// [...]

@storage_var
func _nonce_at(account: felt, block: felt) -> (res: felt) {
}

@storage_var
func _proven_nonce(account: felt, block: felt) -> (res: felt) {
}

@view
func get_verified_account_nonce{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt, block: felt
) -> (res: felt) {
    let (nonce_at) = _nonce_at.read(account, block);
    return (res=nonce_at);
}

@view
func is_nonce_proven{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt, block: felt
) -> (res: felt) {
    let (is_proven) = _proven_nonce.read(account, block);
    return (res=is_proven);
}

// Simple mock of `prove_account` for nonce only.
@external
func prove_account_nonce{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt, at_block: felt, nonce: felt
) -> (res: felt) {
    // @notice The real contract uses storage proofs to cryptographically verify the account and its underlying nonce.
    _nonce_at.write(account, at_block, nonce);
    _proven_nonce.write(account, at_block, 1);
    return (res=nonce);
}

// [...]

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    return ();
}

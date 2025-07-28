use starknet::ContractAddress;

#[derive(Drop, starknet::Event)]
pub struct TipSent {
    page_id: u256,
    sender: ContractAddress,
    creator: ContractAddress,
    token_address: ContractAddress,
    amount: u256,
    usd_value: u256,
    message: ByteArray,
    timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct TokenAdded {
    token_address: ContractAddress,
    symbol: ByteArray,
    decimals: u8,
}

#[derive(Drop, starknet::Event)]
pub struct TokenRemoved {
    token_address: ContractAddress,
}

#[derive(Drop, starknet::Event)]
pub struct TipPageCreated {
    page_id: u256,
    creator: ContractAddress,
    page_name: ByteArray,
}
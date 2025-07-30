use starknet::ContractAddress;

#[derive(Drop, starknet::Event)]
pub struct TipSent {
   pub page_id: u256,
   pub sender: ContractAddress,
   pub creator: ContractAddress,
   // pub token_address: ContractAddress,
   pub amount: u256,
   // pub usd_value: u256,
   pub message: ByteArray,
   pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct TokenAdded {
   pub token_address: ContractAddress,
   pub symbol: ByteArray,
   pub decimals: u8,
}

#[derive(Drop, starknet::Event)]
pub struct TokenRemoved {
   pub token_address: ContractAddress,
}

#[derive(Drop, starknet::Event)]
pub struct TipPageCreated {
    pub page_id: u256,
    pub creator: ContractAddress,
    pub page_name: ByteArray,
    pub description: ByteArray,
    pub created_at: u64,
}
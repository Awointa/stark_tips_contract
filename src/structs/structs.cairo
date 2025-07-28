use starknet::ContractAddress;

#[derive(Clone, Debug, Serde, starknet::Store)]
pub struct TipPage {
    id: u256,
    creator: ContractAddress,
    name: ByteArray,
    description: ByteArray,
    created_at: u64,
    total_tips_recieved: u256,
    total_amount_recieved: u256,
    is_active: bool,    
}

#[derive(Clone, Debug, Serde, starknet::Store)]
pub struct Tip {
    id: u256,
    page_id: u256,
    sender: ContractAddress,
    creator: ContractAddress,
    amount: u256,
    message: ByteArray,
    timestamp: u64,
}

#[derive(Drop, Clone, Debug, Serde, starknet::Store)]
pub struct TokenInfo {
    pub address: ContractAddress,
    pub name: ByteArray,
    pub symbol: ByteArray,
    pub decimals: u8,
    pub is_supported: bool,
    pub min_tip_amount: u256,
}
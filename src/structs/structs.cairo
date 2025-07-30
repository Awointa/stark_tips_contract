use starknet::ContractAddress;

#[derive(Drop, Clone, Debug, Serde, starknet::Store)]
pub struct TipPage {
    pub id: u256,
    pub creator: ContractAddress,
    pub name: ByteArray,
    pub description: ByteArray,
    pub created_at: u64,
    pub total_tips_recieved: u256,
    pub total_amount_recieved: u256,
    pub is_active: bool,    
}

#[derive(Drop, Clone, Debug, Serde, starknet::Store)]
pub struct Tip {
    pub id: u256,
    pub page_id: u256,
    pub sender: ContractAddress,
    pub creator: ContractAddress,
    pub amount: u256,
    pub message: ByteArray,
    pub timestamp: u64,
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
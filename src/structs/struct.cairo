#[derive(Debug, Serde, starknet::store)]
struct TipPage {
    id: u256,
    creator: ContractAddress,
    name: ByteArray,
    description: ByteArray,
    created_at: u64
    total_tips_recieved: u256,
    total_amount_recieved: u256,
    is_active: bool,    
}
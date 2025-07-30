use starknet::ContractAddress;
use stark_tips_contract::structs::structs::{TipPage, Tip};

#[starknet::interface]
pub trait Istarktips<TContractState> {
    fn create_tip_page(
        ref self: TContractState, 
        creator_address: ContractAddress, 
        page_name: ByteArray,
        description: ByteArray
    ) -> u256;
    
    // fn send_tip(
    //     ref self: TContractState, 
    //     page_id: u256, 
    //     amount: u256, 
    //     message: ByteArray
    // );
    
    fn get_page_info(self: @TContractState, page_id: u256) -> TipPage;
    
    // fn get_tips_for_page(self: @TContractState, page_id: u256) -> Array<Tip>;
    
    // fn get_creator_pages(self: @TContractState, creator: ContractAddress) -> Array<u256>;
    
    // fn update_tip_page(
    //     ref self: TContractState,
    //     page_id: u256,
    //     new_name: ByteArray,
    //     new_description: ByteArray
    // );
    
    // fn deactivate_page(ref self: TContractState, page_id: u256);
    
    // fn get_total_pages(self: @TContractState) -> u256;
    
    // fn get_strk_balance(self: @TContractState, account: ContractAddress) -> u256;
    
    // fn get_strk_allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
    
    // fn get_recent_tips(self: @TContractState, limit: u32) -> Array<Tip>;
}
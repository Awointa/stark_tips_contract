#[starknet::contract]
pub mod StarKTips{
    use starknet::{ContractAddress, get_caller_address, get_contract_address, get_block_timestamp, contract_address_const };
    use stark_tips_contract::structs::structs::{TipPage, TokenInfo, Tip};
    use stark_tips_contract::events::events::{TipPageCreated, TipSent, TokenAdded, TokenRemoved};
    use starknet::storage::{Map, StorageMapWriteAccess, 
    StorageMapReadAccess,StoragePointerWriteAccess, StoragePointerReadAccess};

    #[storage]
    struct Storage {
        tip_pages: Map<u256, TipPage>,
        creator_pages: Map<ContractAddress, Array<u256>>, 
        page_tips: Map<u256, Array<Tip>>,
        next_page_id: u256,
        total_pages: u256,
        owner: ContractAddress,

        // Multi-token support
        supported_tokens: Map<ContractAddress, TokenInfo>,
        page_accepted_tokens: Map<u256, Array<ContractAddress>>,
    }

    // Standard ERC20 interface
    #[starknet::interface]
    trait IERC20<TContractState> {
        fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
        fn transfer_from(ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool;
        fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
        fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
        fn name(self: @TContractState) -> ByteArray;
        fn symbol(self: @TContractState) -> ByteArray;
        fn decimals(self: @TContractState) -> u8;
      }

    #[event]
    #[derive(starknet::Event, Drop)]
    enum Event{
        TipPageCreated: TipPageCreated,
        TipSent: TipSent,
        TokenAdded: TokenAdded,
        TokenRemoved: TokenRemoved,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
        self.next_page_id.write(1);
        self.total_pages.write(0);
    }



   

}


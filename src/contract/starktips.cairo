#[starknet::contract]
pub mod StarKTips{
    use starknet::{ContractAddress, get_caller_address, get_contract_address, get_block_timestamp, contract_address_const };
    use stark_tips_contract::structs::structs::{TipPage, TokenInfo, Tip};
    use stark_tips_contract::events::events::{TipPageCreated, TipSent, TokenAdded, TokenRemoved};
    use stark_tips_contract::interface::Istarktips::Istarktips;
    use starknet::storage::{Map, StorageMapWriteAccess, 
    StorageMapReadAccess,StoragePointerWriteAccess, StoragePointerReadAccess};
    use stark_tips_contract::errors::errors::Errors;

    #[storage]
    struct Storage {
        tip_pages: Map<u256, TipPage>,
        creator_page_count: Map<ContractAddress, u256>, 
        creator_pages: Map<(ContractAddress, u256), u256>,  //(creator, index) -> page_id

        page_tip_count: Map<u256, u256>,
        page_tips: Map<(u256, u256), Tip>, //(page_id, index) -> Tip

        next_page_id: u256,
        total_pages: u256,
        owner: ContractAddress,

        // // Multi-token support
        // supported_tokens: Map<ContractAddress, TokenInfo>,
        // page_accepted_tokens: Map<u256, Array<ContractAddress>>,
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


    #[abi(embed_v0)]
    impl  StarkTipsImpl of Istarktips<ContractState>{
        fn create_tip_page(ref self: ContractState, creator_address: ContractAddress, page_name: ByteArray, description: ByteArray) -> u256{
            assert(page_name == "", Errors::EMPTY_NAME);

            let caller = get_caller_address();

            assert(caller == creator_address, Errors::UNAUTHORIZED);

            let page_id = self.next_page_id.read();
            self.next_page_id.write(page_id + 1);

            let tip_page = TipPage {
                id: page_id,
                creator: creator_address,
                name: page_name.clone(),
                description: description.clone(),
                created_at: get_block_timestamp(),
                total_tips_recieved: 0,
                total_amount_recieved: 0,
                is_active: true
            };

            self.tip_pages.write(page_id, tip_page);
          
            let current_count = self.creator_page_count.read(creator_address);
            self.creator_pages.write((creator_address, current_count), page_id);
            self.creator_page_count.write(creator_address, current_count + 1);

            self.total_pages.write(self.total_pages.read() + 1);

            self.emit(Event::TipPageCreated(TipPageCreated {
                page_id: page_id,
                creator: creator_address,
                page_name,
                description: description,
                created_at: get_block_timestamp()
            }));


            page_id
        }
    }
   

}


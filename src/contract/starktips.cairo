// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts for Cairo ^2.0.0

const PAUSER_ROLE: felt252 = selector!("PAUSER_ROLE");
const UPGRADER_ROLE: felt252 = selector!("UPGRADER_ROLE");

#[starknet::contract]
pub mod StarkTips {
    use openzeppelin::access::accesscontrol::{AccessControlComponent, DEFAULT_ADMIN_ROLE};
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::security::pausable::PausableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;
    use openzeppelin::upgrades::UpgradeableComponent;
    use starknet::{ClassHash, ContractAddress};
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use super::{PAUSER_ROLE, UPGRADER_ROLE};

    use starknet::{get_caller_address, get_contract_address, get_block_timestamp, contract_address_const};
    
    use stark_tips_contract::structs::structs::{TipPage, Tip};
    use stark_tips_contract::events::events::{TipPageCreated, TipSent, TipPageDeactivated, TipPageActivated, TokenAdded, TokenRemoved};
    use stark_tips_contract::interface::Istarktips::Istarktips;
    use starknet::storage::{Map, StorageMapWriteAccess, 
    StorageMapReadAccess,StoragePointerWriteAccess, StoragePointerReadAccess};
    use stark_tips_contract::errors::errors::Errors;


    component!(path: PausableComponent, storage: pausable, event: PausableEvent);
    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    // External
    #[abi(embed_v0)]
    impl PausableImpl = PausableComponent::PausableImpl<ContractState>;
    #[abi(embed_v0)]
    impl AccessControlMixinImpl = AccessControlComponent::AccessControlMixinImpl<ContractState>;

    // Internal
    impl PausableInternalImpl = PausableComponent::InternalImpl<ContractState>;
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    // const STRK_CONTRACT_ADDRESS: felt252 = 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        pausable: PausableComponent::Storage,
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,

        tip_pages: Map<u256, TipPage>,
        creator_page_count: Map<ContractAddress, u256>, 
        creator_pages: Map<(ContractAddress, u256), u256>,  //(creator, index) -> page_id

        page_tip_count: Map<u256, u256>,
        page_tips: Map<(u256, u256), Tip>, //(page_id, index) -> Tip

        next_page_id: u256,
        total_pages: u256,
        owner: ContractAddress,

        token_address: ContractAddress, // Address of the STRK token contract
    }

    #[event]
    #[derive(Drop, starknet::Event)]
   pub enum Event {
        #[flat]
        PausableEvent: PausableComponent::Event,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,

        TipPageCreated: TipPageCreated,
        TipSent: TipSent,
        TokenAdded: TokenAdded,
        TokenRemoved: TokenRemoved,
        TipPageDeactivated: TipPageDeactivated,
        TipPageActivated: TipPageActivated,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        default_admin: ContractAddress,
        token_address: ContractAddress
    ) {
        self.accesscontrol.initializer();

        self.accesscontrol._grant_role(DEFAULT_ADMIN_ROLE, default_admin);
        self.accesscontrol._grant_role(PAUSER_ROLE, default_admin);
        self.accesscontrol._grant_role(UPGRADER_ROLE, default_admin);
        self.owner.write(default_admin);
        self.next_page_id.write(1);
        self.total_pages.write(0);
        self.token_address.write(token_address);
    }

    #[generate_trait]
    #[abi(per_item)]
    impl ExternalImpl of ExternalTrait {
        #[external(v0)]
        fn pause(ref self: ContractState) {
            self.accesscontrol.assert_only_role(PAUSER_ROLE);
            self.pausable.pause();
        }

        #[external(v0)]
        fn unpause(ref self: ContractState) {
            self.accesscontrol.assert_only_role(PAUSER_ROLE);
            self.pausable.unpause();
        }
    }

    //
    // Upgradeable
    //
    
    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.accesscontrol.assert_only_role(UPGRADER_ROLE);
            self.upgradeable.upgrade(new_class_hash);
        }
    }

    #[abi(embed_v0)]
    impl  StarkTipsImpl of Istarktips<ContractState>{
        fn create_tip_page(ref self: ContractState, creator_address: ContractAddress, page_name: ByteArray, description: ByteArray) -> u256{
            assert(page_name != "", Errors::EMPTY_NAME);

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
                page_id,
                creator: creator_address,
                page_name,
                description: description,
                created_at: get_block_timestamp()
            }));


            page_id
        }

        fn send_tip(
            ref self: ContractState, 
            page_id: u256, 
            amount: u256, 
            message: ByteArray
        ){
            assert(amount >= 10000000000000000, Errors::INVALID_AMOUNT);

            let mut tip_page = self.tip_pages.read(page_id);
            assert(tip_page.is_active, Errors::PAGE_INACTIVE);
            assert(tip_page.id != 0, Errors::PAGE_NOT_FOUND);

            let sender = get_caller_address();
            let creator = tip_page.creator;

            let strk_contract = IERC20Dispatcher{contract_address: self.token_address.read()};

            let sender_balance = strk_contract.balance_of(sender);
            assert(sender_balance >= amount, Errors::INSUFFICIENT_BALANCE);

            let success = strk_contract.transfer_from(sender, creator, amount);

            assert(success, Errors::TRANSFER_FAILED);

            let _tip = Tip {
                id: self.page_tip_count.read(page_id) + 1,
                page_id,
                sender,
                creator,
                amount,
                message: message.clone(),
                timestamp: get_block_timestamp()
            };

            // ADD THIS LINE - Store the tip in the page_tips mapping
            self.page_tips.write((page_id, _tip.id), _tip);

            tip_page.total_tips_recieved += 1;
            tip_page.total_amount_recieved += amount;
            self.tip_pages.write(page_id, tip_page);

            let mut page_tip_count = self.page_tip_count.read(page_id);
            self.page_tip_count.write(page_id, page_tip_count + 1);

            self.emit(Event::TipSent(TipSent {
                page_id,
                sender,
                creator,
                amount,
                message: message.clone(),
                timestamp: get_block_timestamp()
            }));

        }

        fn get_page_info(self: @ContractState, page_id: u256) -> TipPage {
            let tip_page = self.tip_pages.read(page_id);
            assert(tip_page.id != 0, Errors::PAGE_NOT_FOUND);

            tip_page
        }

        fn get_tips_for_page(self: @ContractState, page_id: u256) -> Array<Tip> {
            let tip_page = self.tip_pages.read(page_id);
            assert(tip_page.is_active, Errors::PAGE_INACTIVE);
            assert(tip_page.id != 0, Errors::PAGE_NOT_FOUND);
            
            let mut tips: Array<Tip> = ArrayTrait::new();
            let mut index: u256 = 1;

            loop {
                let tip = self.page_tips.read((page_id, index));
                if tip.id == 0 {
                    break;
                }
                tips.append(tip);
                index += 1;
            }

            tips
        }

        fn get_creator_pages(self: @ContractState, creator: ContractAddress) -> Array<u256>{
            let mut pages: Array<u256> = ArrayTrait::new();
            let page_count: u256 = self.creator_page_count.read(creator);
            for i in 0..page_count {
                let page_id = self.creator_pages.read((creator, i));
                if page_id != 0 {
                    pages.append(page_id);
                }
            }
            pages
        }

        fn deactivate_page(ref self: ContractState, page_id:u256){
            let mut tip_page = self.tip_pages.read(page_id);
            assert(tip_page.id != 0, Errors::PAGE_NOT_FOUND);

            let caller = get_caller_address();
            assert(caller == tip_page.creator, Errors::UNAUTHORIZED);

            tip_page.is_active = false;
            self.tip_pages.write(page_id, tip_page.clone());

            self.emit(Event::TipPageDeactivated(TipPageDeactivated {
                page_id,
                page_name: tip_page.name,
                creator: tip_page.creator,
                deactivated_at: get_block_timestamp()
            }));

        }

        fn activate_page(ref self: ContractState, page_id:u256){
            let mut tip_page = self.tip_pages.read(page_id);
            assert(tip_page.id != 0, Errors::PAGE_NOT_FOUND);

            let caller = get_caller_address();
            assert(caller == tip_page.creator, Errors::UNAUTHORIZED);

            tip_page.is_active = true;
            self.tip_pages.write(page_id, tip_page.clone());

            self.emit(Event::TipPageActivated(TipPageActivated {
                page_id,
                creator: tip_page.creator,
                page_name: tip_page.name,
                activated_at: get_block_timestamp()
            }));
        }

        fn get_total_pages(self: @ContractState) -> u256 {
            self.total_pages.read()
        }

        // fn get_strk_balance(self: @ContractState, account: ContractAddress) -> u256 {
        //     let strk_contract = IERC20Dispatcher{contract_address: self.token_address.read()};
        //     strk_contract.balance_of(account)
        // }

        // fn get_strk_allowance(self: @ContractState, owner: ContractAddress, spender: ContractAddress) -> u256 {
        //     let strk_contract = IERC20Dispatcher{contract_address: self.token_address.read()};
        //     strk_contract.allowance(owner, spender)
        // }

        fn get_recent_tips(self: @ContractState, limit: u32) -> Array<Tip> {
            let mut tips: Array<Tip> = ArrayTrait::new();
            let total_pages = self.get_total_pages();
            let mut count: u32 = 0;

            for page_id in (1..=total_pages) {
                if count >= limit {
                    break;
                }
                let page_tips = self.get_tips_for_page(page_id);
                for tip in page_tips {
                    if count >= limit {
                        break;
                    }
                    tips.append(tip);
                    count += 1;
                }
            }

            tips
        }
    }
}
































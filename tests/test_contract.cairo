use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

use snforge_std::{ContractClassTrait, DeclareResultTrait, declare, spy_events, start_cheat_caller_address, stop_cheat_caller_address};
use starknet::{ContractAddress, contract_address_const, get_block_timestamp};

use stark_tips_contract::interface::Istarktips::{IstarktipsDispatcher, IstarktipsDispatcherTrait};
// use stark_tips_contract::contract::starktips::StarKTips;
use stark_tips_contract::errors::errors::Errors;
use stark_tips_contract::structs::structs::{TipPage, Tip};


fn setup() -> (ContractAddress, ContractAddress, ContractAddress) {
    // create default admin address
    let owner: ContractAddress = contract_address_const::<'1'>();

    // Deploy mock token for payment
    let token_class = declare("MockToken").unwrap().contract_class();
    let (token_address, _) = token_class
        .deploy(@array![owner.into(), // recipient
        owner.into() // owner
        ])                                                                      
        .unwrap();

    // deploy store contract
    let declare_result = declare("StarkTips");
    assert(declare_result.is_ok(), 'contract declaration failed');

    let contract_class = declare_result.unwrap().contract_class();
    let mut calldata = array![owner.into(), token_address.into()];

    let deploy_result = contract_class.deploy(@calldata);
    assert(deploy_result.is_ok(), 'contract deployment failed');

    let (contract_address, _) = deploy_result.unwrap();

    (contract_address, owner, token_address)
}

#[test]
fn test_create_tip_page() { 
    let (contract_address, _, _) = setup();
    let dispatcher = IstarktipsDispatcher {contract_address};

    let user: ContractAddress = contract_address_const::<'2'>();

    start_cheat_caller_address(contract_address, user);

    let page_name: ByteArray = "Test Page";
    let description: ByteArray  = "This is a test page";
    let created_at = get_block_timestamp();

    let page_id = dispatcher.create_tip_page(user, page_name, description.clone());
    
    // Verify the page was created
    let tip_page: TipPage = dispatcher.get_page_info(page_id);
    assert_eq!(tip_page.name, "Test Page");
    assert_eq!(tip_page.description, description);
    assert_eq!(tip_page.creator, user);
    assert_eq!(tip_page.created_at, created_at);
    assert_eq!(tip_page.is_active, true);
    
    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_send_tip(){
    let (contract_address, _, token_address) = setup();
    let dispatcher = IstarktipsDispatcher {contract_address};

    let user: ContractAddress = contract_address_const::<'2'>();

    start_cheat_caller_address(contract_address, user);

    let page_name: ByteArray = "Test Page";
    let description: ByteArray  = "This is a test page";

    // Create a tip page
    let page_id = dispatcher.create_tip_page(user, page_name, description.clone());
    
    // Send a tip
    let amount: u256 = 10000000000000000; // 0.01 STRK
    let message: ByteArray = "Great work!";
    
    dispatcher.send_tip(page_id, amount, message.clone());

    // Verify the tip was sent
    let tip_page: TipPage = dispatcher.get_page_info(page_id);
    assert_eq!(tip_page.total_tips_recieved, 1);
    assert_eq!(tip_page.total_amount_recieved, amount);

    stop_cheat_caller_address(contract_address);
}
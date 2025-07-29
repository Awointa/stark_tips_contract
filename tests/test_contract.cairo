
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare, spy_events, start_cheat_caller_address, stop_cheat_caller_address};
use starknet::{ContractAddress, contract_address_const, get_block_timestamp};

use stark_tips_contract::contract::starktips::StarKTips;
use stark_tips_contract::errors::errors::Errors;
use stark_tips_contract::interface::Istarktips::Istarktips;
use stark_tips_contract::structs::structs::{TipPage, Tip};


fn setup() -> (ContractAddress, ContractAddress, ContractAddress){
    let owner = contract_address_const::<'owner'>();

    // Deploy MockToken for payment
    let token_class = declare("MockToken").unwrap().contract_class();
    let (token_address, _) = token_class.deploy(@array![owner.into(), owner.into()]).unwrap();

    let declare_result = declare("StarKTips");
    assert!(declare_result.is_ok(), "Failed to declare StarKTips contract");

    let contract_class = declare_result.unwrap().contract_class();
    let mut calldata = array![owner.into(), token_address.into()];

    let deploy_result = contract_class.deploy(@calldata);
    assert!(deploy_result.is_ok(), "Failed to deploy StarKTips contract");

    let (contract_address, _) = deploy_result.unwrap();

    (contract_address, owner, token_address)

}

pub mod Errors {
    pub const PAGE_NOT_FOUND: felt252 = 'Page not found';
    pub const PAGE_INACTIVE: felt252 = 'Page is inactive';
    pub const INVALID_AMOUNT: felt252 = 'Invalid tip amount';
    pub const TRANSFER_FAILED: felt252 = 'STRK transfer failed';
    pub const INSUFFICIENT_ALLOWANCE: felt252 = 'Insufficient STRK allowance';
    pub const INSUFFICIENT_BALANCE: felt252 = 'Insufficient STRK balance';
    pub const UNAUTHORIZED: felt252 = 'Unauthorized access';
    pub const EMPTY_NAME: felt252 = 'Page name cannot be empty';
}
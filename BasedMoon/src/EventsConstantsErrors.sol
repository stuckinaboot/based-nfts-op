// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 .0;

contract EventsConstantsErrors {
  uint256 internal constant PRICE = 0.001 ether;
  uint256 internal constant _allowListMintMaxPerWallet = 10;
  address payable internal constant _VAULT_ADDRESS = payable(address(0x39Ab90066cec746A032D67e4fe3378f16294CF6b));

  error TokenUnknown();
  error InvalidPaymentAmount();
  error MintClosed();
  error AllowListMintCapPerWalletExceeded();
}

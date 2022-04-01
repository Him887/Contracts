// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Token
 * @dev API interface for interacting with the WILD Token contract 
 */
interface Token {
  function transfer(address _to, uint256 _value) external returns (bool);
  function balanceOf(address _owner) external returns (uint256 balance);
}

/**
 * @title TestICO
 * @dev TestICO contract is Ownable
 **/
contract TestICO is Ownable {
  using SafeMath for uint256;
  Token token;

  uint256 public constant RATE = 10000; // Number of tokens per Ether
  uint256 public constant START = 1648057976; // 
  uint256 public constant DAYS = 90; // 90 Day
  
  uint256 public constant initialTokens = 10000000 * 10**18; // Initial number of tokens available
  bool public initialized = false;
  uint256 public raisedAmount = 0;
  
  address payable ownerWallet;

  event BoughtTokens(address indexed to, uint256 value);

  modifier whenSaleIsActive() {
    // Check if sale is active
    assert(isActive());
    _;
  }
  
  constructor(address _tokenAddr) {
      require(_tokenAddr != address(0));
      token = Token(_tokenAddr);
      ownerWallet = payable(owner());
  }

  function initialize() public onlyOwner {
      require(initialized == false); // Can only be initialized once
      require(tokensAvailable() == initialTokens); // Must have enough tokens allocated
      initialized = true;
  }

  function isActive() public view returns (bool) {
    return (
        initialized == true &&
        block.timestamp >= START && // Must be after the START date
        block.timestamp <= START.add(DAYS * 1 days) && // Must be before the end date
        tokensAvailable() > 0
    );
  }

  /**
   * @dev Fallback function if ether is sent to address insted of buyTokens function
   **/
  fallback() external payable {
    buyTokens();
  }

  receive() external payable {
    buyTokens();
  }

  /**
   * buyTokens
   * @dev function that sells available tokens
   **/
  function buyTokens() public payable whenSaleIsActive {
    require(msg.value > 0, "Cannot send negative balance");

    uint256 weiAmount = msg.value; 
    uint256 tokens = weiAmount.mul(RATE); // Calculate tokens to sell
    
    require(tokensAvailable() >= tokens , "Enough tokens not Available");

    emit BoughtTokens(msg.sender, tokens); // log event onto the blockchain

    raisedAmount = raisedAmount.add(msg.value); // Increment raised amount
    (bool ok,) = ownerWallet.call{value: msg.value}(''); // Send money to owner
    
    require(ok, 'Traansaction Failed');
 
    token.transfer(msg.sender, tokens); // Send tokens to buyer
  }

  /**
   * tokensAvailable
   * @dev returns the number of tokens allocated to this contract
   **/
  function tokensAvailable() public view returns (uint256) {
    return token.balanceOf(address(this));
  }

  /**
   * destroy
   * @notice Terminate contract and refund to owner
   **/
  function destroy() onlyOwner public {
    // Transfer tokens back to owner
    uint256 balance = token.balanceOf(address(this));
    assert(balance > 0);
    token.transfer(ownerWallet, balance);
    // There should be no ether in the contract but just in case
    selfdestruct(ownerWallet);
  }
}

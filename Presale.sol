pragma solidity ^0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner)public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

/**
 * @title Token
 * @dev API interface for interacting with the Litrabi Token contract 
 */
interface Token {
  function transfer(address _to, uint256 _value)external returns (bool);
  function balanceOf(address _owner)external view returns (uint256 balance);
}

contract PreSale is Ownable {

  using SafeMath for uint256;

  Token public token;

  uint256 public RATE = 0; // Number of tokens per Ether
  uint256 public CAP = 0; // Cap in Ether
  uint256 public constant START = 1526644800; // May 18, 2018 @ 12 AM
  uint256 public constant DAYS = 15; // 15 Days

  uint256 public constant initialTokens = 2000000 * 10**18; // Initial number of tokens available
  bool public initialized = false;
  uint256 public raisedAmount = 0;
  uint256 public soldTokens = 0;

  event BoughtTokens(address indexed to, uint256 value);

  modifier whenSaleIsActive() {
    // Check if sale is active
    assert(isActive());

    _;
  }

  function PreSale(address _tokenAddr)public {
      require(_tokenAddr != 0);
      token = Token(_tokenAddr); // Address of Litrabit Token to be sold 
  }
  
  function initialize()public onlyOwner {
      require(initialized == false); // Can only be initialized once
      require(tokensAvailable() == initialTokens); // Must have some tokens allocated
      initialized = true;
  }

  function isActive()public view returns (bool) {
    return (
        initialized == true &&
        now >= START && // Must be after the START date
        now <= START.add(DAYS * 1 days) && // Must be before the end date
        goalReached() == false // Goal must not already be reached
    );
  }

  function changeRate(uint256 newRate) public onlyOwner {
      RATE = newRate;
  }    
  
  function changeCap(uint256 newCap) public onlyOwner {
      CAP = newCap;
  }    
  
  function goalReached() public view returns (bool) {
    return (raisedAmount >= CAP * 1 ether);
  }

  function ()public payable {
    buyTokens();
  }

  /**
  * @dev function that sells available tokens
  */
  function buyTokens() public payable whenSaleIsActive {

    // Calculate tokens to sell
    uint256 weiAmount = msg.value;
    uint256 tokens = weiAmount.mul(RATE);

    emit BoughtTokens(msg.sender, tokens);

    // Increment raised amount
    raisedAmount = raisedAmount.add(msg.value);
    
    // Increment raised tokens
    soldTokens = soldTokens.add(tokens);
    
    // Send tokens to buyer
    token.transfer(msg.sender, tokens);
    
    // Send money to owner
    owner.transfer(msg.value);
  }

  /**
   * @dev returns the number of tokens allocated to this contract
   */
  function tokensAvailable()public view returns (uint256) {
    return token.balanceOf(this);
  }

  /**
   * @notice Burn Tokens, Terminate contract and send any ETH left in contract to owner
   */
  function destroy()public onlyOwner {
    // Burn tokens in the contract
    uint256 balance = token.balanceOf(this);
    assert(balance > 0);
    token.transfer(address(0), balance);

    // There should be no ether in the contract but just in case
    selfdestruct(owner);
  }

}

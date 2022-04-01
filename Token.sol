// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Token is ERC20, ERC20Burnable, ERC20Snapshot, Ownable, Pausable, ReentrancyGuard {
    mapping (address => bool) canSnapshot;
    mapping (address => bool) canBurn;
    address public teamAddress;
    uint256 public sellFee;
    event SellFeeChanged(uint256 indexed fee);
    event TeamAddressChanged(address indexed addr);
    constructor(address _teamAddress) 
    ERC20("Token", "Tkn") {    
        teamAddress = _teamAddress;
        _mint(teamAddress, 1e9 * 10** decimals());
        canSnapshot[msg.sender] = true;
    }

    function snapshot() public {
        require(canSnapshot[msg.sender], "sender cannot snapshot");
        _snapshot();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function transfer(address to, uint256 amount) public override(ERC20) 
    returns (bool) {
      uint256 fee = 0;
      if(to != teamAddress)
        fee += amount * sellFee / 100;
      if (fee > 0) {
        require(super.transfer(address(this), fee), 'fee transaction failed');
      }
      return super.transfer(to, amount - fee);
    }

    function transferFrom(address from, address to, uint256 amount) public override(ERC20) 
    returns (bool) {
      uint256 fee = 0;
      if(to != teamAddress)
        fee += amount * sellFee / 100;
      if (fee > 0) {
        require(super.transferFrom(from, address(this), fee), 'fee transaction failed');
      }
      return super.transferFrom(from, to, amount - fee);
    }

    function burn(uint256 amount)  override public {
      require(canBurn[msg.sender], "permission denied");
      _burn(msg.sender, amount);
    }
    // The following functions are overrides required by Solidity.
    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal nonReentrant
        override(ERC20)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20)
    {
        super._burn(account, amount);
    }
	
    function setSnapshotCapability(address addr, bool val) external onlyOwner {
      require(addr != address(0));
      canSnapshot[addr] = val;
    }
    
    function setBurnCapability(address addr, bool val) external onlyOwner {
      require(addr != address(0));
      canBurn[addr] = val;
    }

    function setSellFee(uint256 _fee) external onlyOwner {
      sellFee = _fee;
      emit SellFeeChanged(_fee);
    }
    
    function setTeamAddress(address _addr) external onlyOwner {
      require(_addr != address(0));
      teamAddress = _addr;
      emit TeamAddressChanged(_addr);
    }

    function withdrawMatic() external onlyOwner {
      (bool ok,) = msg.sender.call{value: address(this).balance}('');
      require(ok, 'withdraw transaction failed');
    }

    function withdrawToken() external onlyOwner {
      uint256 balance = balanceOf(address(this));
      SafeERC20.safeTransfer(IERC20(address(this)), msg.sender, balance);
    }

		receive() external payable {
		}

    fallback() external payable {
		}

}
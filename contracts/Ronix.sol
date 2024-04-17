// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract RonixToken is
    ERC20,
    ERC20Burnable,
    ERC20Pausable,
    AccessControl,
    ERC20Permit
{
    using SafeERC20 for IERC20;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    IERC20 public usdtToken;

    event Deposit(address indexed user, uint256 usdtAmountIn, uint256 ronixAmountOut);
    event Withdrawal(address indexed user, uint256 ronixAmountIn, uint256 usdtAmountOut);

    constructor(
        address _usdtAddress
    ) ERC20("RonixToken", "Ronix") ERC20Permit("RonixToken") {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());

        usdtToken = IERC20(_usdtAddress);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function getReserves()
        public
        view
        returns (
            uint256 _usdtAmount,
            uint256 _ronixAmount
        )
    {
        _usdtAmount = usdtToken.balanceOf(address(this));
        _ronixAmount = totalSupply();
    }

    function getAmountOut(uint256 _usdtAmountIn) public view returns (uint256) {
        (uint256 usdtReserve, uint256 ronixReserve) = getReserves();
        uint256 ronixAmountOut = _usdtAmountIn;
        if (usdtReserve != 0) {
            ronixAmountOut = (_usdtAmountIn * ronixReserve) / usdtReserve;
        }
        return ronixAmountOut;
    }

    function getAmountIn(uint256 ronixAmountOut) public view returns (uint256) {
        (uint256 usdtReserve, uint256 ronixReserve) = getReserves();
        uint256 usdtAmountIn = ronixAmountOut;
        if (ronixReserve != 0) {
            usdtAmountIn = (ronixAmountOut * usdtReserve) / ronixReserve;
        }
        return usdtAmountIn;
    }

    function deposit(uint256 usdtAmountIn) public {
        uint256 ronixAmountOut = getAmountOut(usdtAmountIn);

        usdtToken.safeTransferFrom(_msgSender(), address(this), usdtAmountIn);
        _mint(_msgSender(), ronixAmountOut);

        emit Deposit(_msgSender(), usdtAmountIn, ronixAmountOut);
    }

    function withdraw(uint256 ronixAmountIn) public {
        require(balanceOf(_msgSender()) >= ronixAmountIn, "OVER VALUE");
        (uint256 usdtReserve, uint256 ronixReserve) = getReserves();
        require(ronixAmountIn < ronixReserve, "CAN NOT WITHDRAW ALL RONIX");
        burn(ronixAmountIn);

        uint256 usdtAmountOut = ronixAmountIn;
        if (ronixReserve != 0) {
            usdtAmountOut = ronixAmountIn * usdtReserve / ronixReserve;
        }
        
        usdtToken.safeTransfer(_msgSender(), usdtAmountOut);
        
        emit Withdrawal(_msgSender(), ronixAmountIn, usdtAmountOut);
    }

    // The following functions are overrides required by Solidity.

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Pausable) {
        super._update(from, to, value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./interfaces/IERC20Extension.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IStaking.sol";

contract Collateral is UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    address public treasuryAddress;
    address public ronixAddress;
    address public usdtAddress;
    address public stakingAddress;
    uint256 targetGrowthRatePerRebase;
    uint256 totalRebase;

    event Deposit(
        address indexed user,
        uint256 usdtAmountIn,
        uint256 ronixAmountOut
    );
    event Withdrawal(
        address indexed user,
        uint256 ronixAmountIn,
        uint256 usdtAmountOut
    );

    function initialize(
        address _treasuryAddress,
        address _ronixAddress,
        address _usdtAddress,
        address _stakingAddress,
        uint256 _targetGrowthRatePerRebase
    ) external initializer {
        treasuryAddress = _treasuryAddress;
        ronixAddress = _ronixAddress;
        usdtAddress = _usdtAddress;
        stakingAddress = _stakingAddress;
        targetGrowthRatePerRebase = _targetGrowthRatePerRebase;
        __Ownable_init(msg.sender);
    }

    function setTargetGrowthRatePerRebase(
        uint256 _targetGrowthRatePerRebase
    ) external {
        targetGrowthRatePerRebase = _targetGrowthRatePerRebase;
    }

    function getReserves()
        public
        view
        returns (uint256 _usdtAmount, uint256 _ronixAmount)
    {
        _usdtAmount = IERC20(usdtAddress).balanceOf(address(this));
        _ronixAmount = IERC20(ronixAddress).totalSupply();
    }

    function depositUSDT(uint256 usdtAmountIn) external {
        (, uint256 ronixReserve) = getReserves();
        uint256 ronixAmountOut = usdtAmountIn /
            (ronixReserve * targetGrowthRatePerRebase);

        IERC20(usdtAddress).safeTransferFrom(
            _msgSender(),
            address(this),
            usdtAmountIn
        );
        IERC20Extension(ronixAddress).mint(_msgSender(), ronixAmountOut);

        emit Deposit(_msgSender(), usdtAmountIn, ronixAmountOut);
    }

    function withdrawUSDT(uint256 ronixAmountIn) external {
        require(
            IERC20(ronixAddress).balanceOf(_msgSender()) >= ronixAmountIn,
            "OVER VALUE"
        );

        (uint256 usdtReserve, uint256 ronixReserve) = getReserves();
        require(ronixAmountIn < ronixReserve, "CAN NOT WITHDRAW ALL RONIX");

        IERC20Extension(ronixAddress).burnFrom(_msgSender(), ronixAmountIn);

        uint256 usdtAmountOut = ronixAmountIn;
        if (ronixReserve != 0) {
            usdtAmountOut = (ronixAmountIn * usdtReserve) / ronixReserve;
        }

        IERC20(usdtAddress).safeTransfer(_msgSender(), usdtAmountOut);

        emit Withdrawal(_msgSender(), ronixAmountIn, usdtAmountOut);
    }

    // function rebaseRonix() external {
    //     uint256 totalNFTs = IStaking(stakingAddress).totalNFTs();

    //     // snapshot
    // }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}

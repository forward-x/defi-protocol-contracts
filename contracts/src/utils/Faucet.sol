// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

import "../../externalContract/openzeppelin/non-upgradeable/SafeERC20.sol";
import "../../externalContract/openzeppelin/non-upgradeable/IERC20.sol";
import "../../externalContract/openzeppelin/non-upgradeable/Ownable.sol";

contract Faucet is Ownable {
    using SafeERC20 for IERC20;

    uint256 public cooldown;
    address[] public tokensAddress;

    /* Map cooldown user faucet time for each token */
    mapping(address => mapping(address => uint256)) public usersNextCooldown;

    /* Map token address with faucetAmount */
    mapping(address => uint256) public faucetsAmount;

    /* Map added token address */
    mapping(address => bool) public isTokensActive;

    constructor() {
        cooldown = 23 hours;
    }

    event FaucetTransfer(
        address indexed to,
        address tokenAddress,
        uint256 value,
        uint256 timestamp
    );

    modifier avoidZeroAddress(address _address) {
        require(
            _address != address(0),
            "Faucet/recipient-address-cound-not-be-0x00"
        );
        _;
    }

    modifier checkAllowedToWithdraw(address _tokenAddress) {
        // Check available token and cooldown
        // msg.sender so any contract can call this function
        require(
            faucetsAmount[_tokenAddress] > 0,
            "Faucet/token-is-not-available"
        );
        require(
            usersNextCooldown[msg.sender][_tokenAddress] == 0 ||
                usersNextCooldown[msg.sender][_tokenAddress] <= block.timestamp,
            "Faucet/withdraw-unavaildable-due-to-cooldown"
        );
        _;
    }

    function setTokenRequestPerRound(
        address _tokenAddress,
        uint256 _amount
    ) public onlyOwner avoidZeroAddress(_tokenAddress) {
        faucetsAmount[_tokenAddress] = _amount;
        if (!isTokensActive[_tokenAddress]) {
            tokensAddress.push(_tokenAddress);
            isTokensActive[_tokenAddress] = true;
        }
    }

    function setCooldown(uint256 _cooldown) public onlyOwner {
        cooldown = _cooldown;
    }

    function requestToken(
        address _tokenAddress
    ) public checkAllowedToWithdraw(_tokenAddress) {
        uint256 _tokenBalance = getTokenBalance(_tokenAddress);
        require(
            _tokenBalance >= faucetsAmount[_tokenAddress],
            "Faucet/insufficient-balance"
        );

        IERC20(_tokenAddress).safeTransfer(
            msg.sender,
            faucetsAmount[_tokenAddress]
        );
        usersNextCooldown[msg.sender][_tokenAddress] =
            block.timestamp +
            cooldown;

        emit FaucetTransfer(
            msg.sender,
            _tokenAddress,
            faucetsAmount[_tokenAddress],
            block.timestamp
        );
    }

    function getTokenBalance(
        address _tokenAddress
    ) public view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    function getAllBalance()
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256 tokenIndex = 0;
        uint256 count = 0;
        address[] memory _tokensAddress = new address[](tokensAddress.length);
        uint256[] memory _tokensBalance = new uint256[](tokensAddress.length);
        while (tokenIndex < tokensAddress.length) {
            if (faucetsAmount[tokensAddress[tokenIndex]] > 0) {
                _tokensAddress[count] = tokensAddress[tokenIndex];
                _tokensBalance[count] = IERC20(tokensAddress[tokenIndex])
                    .balanceOf(address(this));
                count++;
            }
            tokenIndex++;
        }
        tokenIndex = tokenIndex - count;
        assembly {
            mstore(_tokensAddress, sub(mload(_tokensAddress), tokenIndex))
        }
        assembly {
            mstore(_tokensBalance, sub(mload(_tokensBalance), tokenIndex))
        }
        return (_tokensAddress, _tokensBalance);
    }
}

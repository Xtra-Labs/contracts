// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./GetExchangeRate.sol";

contract SupplyLending {
    // Contract variables and state
    struct UserSupplyInfo {
        address TokenAddress;
        uint256 TokenAmount;
    }

    struct Token {
        string symbol;
        uint256 TokenAmount;
    }

    uint LTV = 80;

    GetExchangeRate getExchangeRate = new GetExchangeRate();

    mapping(address => string) private tokenSymbol;
    mapping(address => bool) public tokenExists;
    address[] public tokenAddresses;
    // map -> user returns map with tokenAddress -> supply
    mapping(address => mapping(address => uint256)) private userTokenSupplies;
    mapping(address => mapping(address => uint256)) private userTokenBorrowings;
    mapping(address => uint256) private totalTokenSupply;
    address public owner;
    string public nativeTokenSymbol;

    // Constructor
    constructor(string memory _nativeTokenSymbol) {
        // Initialize contract state
        owner = msg.sender;
        tokenAddresses.push(address(0));
        nativeTokenSymbol = _nativeTokenSymbol;
    }

    // Contract functions and logic
    function addToken(
        address _tokenAddress,
        string memory _tokenSymbol
    ) public {
        require(msg.sender == owner, "Only owner can add tokens");
        require(
            keccak256(abi.encode(_tokenSymbol)) != keccak256(abi.encode("")),
            "Token symbol is required"
        );
        require(_tokenAddress != address(0), "Token address is required");

        tokenSymbol[_tokenAddress] = _tokenSymbol;
        tokenExists[_tokenAddress] = true;
        tokenAddresses.push(_tokenAddress);
    }

    function addSupply(uint _amount, address _tokenAddress) public {
        require(_amount > 0, "Amount must be greater than 0");
        require(_tokenAddress != address(0), "Token address cannot be 0");
        require(tokenExists[_tokenAddress], "Token does not exist");

        IERC20 token = IERC20(_tokenAddress);

        require(
            token.allowance(msg.sender, address(this)) >= _amount,
            "Token allowance too low"
        );

        token.transferFrom(msg.sender, address(this), _amount);

        uint256 existingSupply = userTokenSupplies[msg.sender][_tokenAddress];
        userTokenSupplies[msg.sender][_tokenAddress] = existingSupply + _amount;

        uint256 existingTotalSupply = totalTokenSupply[_tokenAddress];
        totalTokenSupply[_tokenAddress] = existingTotalSupply + _amount;
    }

    function addSupplyNative() public payable {
        require(msg.value > 0, "Amount must be greater than 0");

        uint256 existingSupply = userTokenSupplies[msg.sender][address(0)];
        userTokenSupplies[msg.sender][address(0)] = existingSupply + msg.value;

        uint256 existingTotalSupply = totalTokenSupply[address(0)];
        totalTokenSupply[address(0)] = existingTotalSupply + msg.value;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function viewUserSupplies(
        address _user
    ) public view returns (UserSupplyInfo[] memory) {
        UserSupplyInfo[] memory userSupplies = new UserSupplyInfo[](
            tokenAddresses.length
        );

        for (uint i = 0; i < tokenAddresses.length; i++) {
            address tokenAddress = tokenAddresses[i];
            userSupplies[i] = UserSupplyInfo(
                tokenAddress,
                userTokenSupplies[_user][tokenAddress]
            );
        }

        return userSupplies;
    }

    function viewAvailableTokens() public view returns (Token[] memory) {
        Token[] memory allTokens = new Token[](tokenAddresses.length);

        for (uint i = 0; i < tokenAddresses.length; i++) {
            address tokenAddress = tokenAddresses[i];
            allTokens[i] = Token(
                tokenSymbol[tokenAddress],
                totalTokenSupply[tokenAddress]
            );
        }

        return allTokens;
    }

    function borrowTokenERC20(
        uint _amount,
        address _tokenAddress,
        address _collateralTokenAddress
    ) public {
        require(_amount > 0, "Amount must be greater than 0");
        require(_tokenAddress != address(0), "Token address cannot be 0");

        uint256 userExistingSupply = userTokenSupplies[msg.sender][
            _collateralTokenAddress
        ];
        require(userExistingSupply > 0, "No collateral available");

        (int collateralPrice, uint8 collateralDecimals) = getExchangeRate
            .getChainlinkDataFeedLatestAnswer(
                tokenSymbol[_collateralTokenAddress]
            );
        (int borrowPrice, uint8 borrowDecimals) = getExchangeRate
            .getChainlinkDataFeedLatestAnswer(tokenSymbol[_tokenAddress]);

        uint maxBorrowAmount = (uint(collateralPrice) *
            (10 ** borrowDecimals) *
            userExistingSupply *
            LTV) / (uint(borrowPrice) * (10 ** collateralDecimals) * 100);

        require(_amount <= maxBorrowAmount, "Amount exceeds LTV");

        IERC20 token = IERC20(_tokenAddress);

        token.transfer(msg.sender, _amount);

        uint256 existingBorrows = userTokenBorrowings[msg.sender][
            _tokenAddress
        ];
        userTokenBorrowings[msg.sender][_tokenAddress] =
            existingBorrows +
            _amount;
    }

    function borrowERC20TokenIfCollateralNative(
        uint _amount,
        address _tokenAddress
    ) public {
        require(_amount > 0, "Amount must be greater than 0");
        require(_tokenAddress != address(0), "Token address cannot be 0");

        uint256 userExistingSupply = userTokenSupplies[msg.sender][address(0)];
        require(userExistingSupply > 0, "No collateral available");

        (int collateralPrice, uint8 collateralDecimals) = getExchangeRate
            .getChainlinkDataFeedLatestAnswer(nativeTokenSymbol);
        (int borrowPrice, uint8 borrowDecimals) = getExchangeRate
            .getChainlinkDataFeedLatestAnswer(tokenSymbol[_tokenAddress]);

        uint maxBorrowAmount = (uint(collateralPrice) *
            (10 ** borrowDecimals) *
            userExistingSupply *
            LTV) / (uint(borrowPrice) * (10 ** collateralDecimals) * 100);

        require(_amount <= maxBorrowAmount, "Amount exceeds LTV");

        IERC20 token = IERC20(_tokenAddress);

        token.transfer(msg.sender, _amount);

        uint256 existingBorrows = userTokenBorrowings[msg.sender][
            _tokenAddress
        ];
        userTokenBorrowings[msg.sender][_tokenAddress] =
            existingBorrows +
            _amount;
    }
}

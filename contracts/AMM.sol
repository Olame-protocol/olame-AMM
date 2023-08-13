// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AMM is ERC20 {

    /**
    * @dev The address of the Olame token contract.
    */
    address public olameTokenAddress;

    /**
     * @dev Emitted when liquidity is added to the contract.
     * @param provider The address of the liquidity provider.
     * @param amount The amount of tokens provided.
     * @param liquidity The amount of liquidity tokens minted.
     */
    event LiquidityAdded(address indexed provider, uint256 amount, uint256 liquidity);

    /**
     * @dev Emitted when liquidity is removed from the contract.
     * @param provider The address of the liquidity provider.
     * @param amount The amount of liquidity tokens burned.
     * @param celoAmount The amount of CELO tokens transferred to the provider.
     * @param olameTokenAmount The amount of Olame tokens transferred to the provider.
     */
    event LiquidityRemoved(address indexed provider, uint256 amount, uint256 celoAmount, uint256 olameTokenAmount);

    /**
     * @dev Emitted when tokens are purchased from the contract.
     * @param buyer The address of the buyer.
     * @param celoAmount The amount of CELO tokens provided.
     * @param tokensBought The amount of Olame tokens bought.
     */
    event TokensPurchased(address indexed buyer, uint256 celoAmount, uint256 tokensBought);

    /**
     * @dev Emitted when tokens are sold to the contract.
     * @param seller The address of the seller.
     * @param tokensSold The amount of Olame tokens sold.
     * @param celoAmount The amount of CELO tokens transferred to the seller.
     */
    event TokensSold(address indexed seller, uint256 tokensSold, uint256 celoAmount);


    /**
     * @dev Initializes the AMM contract.
     * @param _olameTokenAddress The address of the Olame token.
     */
    constructor(address _olameTokenAddress) ERC20("Olame LP Token", "ICB-LP") {
        require(_olameTokenAddress != address(0), "Token address passed is a null address");
        olameTokenAddress = _olameTokenAddress;
    }


    /**
     * @dev Returns the reserve of Olame tokens held by the contract.
     * @return The reserve of Olame tokens.
     */
    function getReserve() public view returns (uint) {
        return ERC20(olameTokenAddress).balanceOf(address(this));
    }

    /**
     * @dev Adds liquidity to the AMM contract.
     * @param _amount The amount of Olame tokens to add.
     * @return The amount of liquidity added.
     */
    function addLiquidity(uint _amount) public payable returns (uint) {
        uint liquidity;
        uint celoBalance = address(this).balance;
        uint olameTokenReserve = getReserve();
        ERC20 olameToken = ERC20(olameTokenAddress);
        if(olameTokenReserve == 0) {
            require(olameToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
            liquidity = celoBalance;
            _mint(msg.sender, liquidity);
        } else {
            uint celoReserve = celoBalance - msg.value;
            uint olameTokenAmount = (msg.value * olameTokenReserve)/(celoReserve);
            require(_amount >= olameTokenAmount, "Amount of tokens sent is less than the minimum tokens required");
            require(olameToken.transferFrom(msg.sender, address(this), olameTokenAmount), "Token transfer failed");
            liquidity = (msg.value * totalSupply()) / celoReserve;
            require(liquidity > 0, "Liquidity amount is zero");
            _mint(msg.sender, liquidity);
        }
        emit LiquidityAdded(msg.sender, _amount, liquidity);
         return liquidity;
    }

    /**
     * @dev Removes liquidity from the AMM contract.
     * @param _amount The amount of LP tokens to remove.
     * @return The amount of CELO and Olame tokens received.
     */
    function removeLiquidity(uint _amount) public returns (uint , uint) {
        require(_amount > 0, "LP amount must be greater than zero");
        require(balanceOf(msg.sender) >= _amount, "Insufficient LP tokens to burn");
        uint celoReserve = address(this).balance;
        uint _totalSupply = totalSupply();
        uint celoAmount = (celoReserve * _amount)/ _totalSupply;
        uint olameTokenAmount = (getReserve() * _amount)/ _totalSupply;
        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(celoAmount);
        ERC20(olameTokenAddress).transfer(msg.sender, olameTokenAmount);
        emit LiquidityRemoved(msg.sender, _amount, celoAmount, olameTokenAmount);
        return (celoAmount, olameTokenAmount);
    }

    /**
     * @dev Calculates the amount of output tokens for a given input amount and reserves.
     * @param inputAmount The input amount of tokens.
     * @param inputReserve The input reserve of tokens.
     * @param outputReserve The output reserve of tokens.
     * @return The amount of output tokens.
     */
    function getAmountOfTokens(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "Invalid reserves");
        uint256 inputAmountWithFee = inputAmount * 99;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;
        return numerator / denominator;
    }


    /**
     * @dev Swaps CELO for Olame tokens.
     * @param _minTokens The minimum amount of Olame tokens expected to be received.
     */
    function celoToOlameToken(uint _minTokens) public payable {
        uint256 tokenReserve = getReserve();
        
        uint256 tokensBought = getAmountOfTokens(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
        );

        require(tokensBought >= _minTokens, "Insufficient output amount");
        ERC20(olameTokenAddress).transfer(msg.sender, tokensBought);
        require(checkTransferSuccess(), "Token transfer failed");
        emit TokensPurchased(msg.sender, msg.value, tokensBought);
    }

    /**
    * @dev Checks if the token transfer from the contract to itself is successful.
    * @return A boolean indicating whether the transfer was successful or not.
    */
    function checkTransferSuccess() private returns (bool) {
    uint256 tokenBalance = ERC20(olameTokenAddress).balanceOf(address(this));
    return (tokenBalance == 0 || ERC20(olameTokenAddress).transfer(address(this), tokenBalance));
    }


    /**
     * @dev Swaps Olame tokens for CELO.
     * @param _tokensSold The amount of Olame tokens to sell.
     * @param _minCelo The minimum amount of CELO expected to be received.
     */
    function olameTokenToCelo(uint _tokensSold, uint _minCelo) public {
        uint256 tokenReserve = getReserve();
        
        uint256 celoBought = getAmountOfTokens(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );
        require(celoBought >= _minCelo, "Insufficient output amount");
        require(
            ERC20(olameTokenAddress).transferFrom(
                msg.sender,
                address(this),
                _tokensSold
            ),
            "Token transfer failed"
        );
        payable(msg.sender).transfer(celoBought);
        emit TokensSold(msg.sender, _tokensSold, celoBought);
    }
}

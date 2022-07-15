pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./BancorFormula.sol";
import "hardhat/console.sol";

/**
 * @title Universal Bonding Curve
 * @dev Bonding curve contract based on bacor formula
 * inspired by bancor protocol and simondlr
 * https://github.com/bancorprotocol/contracts
 * https://github.com/ConsenSys/curationmarkets/blob/master/CurationMarkets.sol
 * uses bancor formula
 */
contract BondingCurveUniversal is ERC20, BancorFormula, Ownable {
    uint256 public poolBalance;

    constructor() ERC20("BondingCurve", "BC") {}

    /*
    reserve ratio, represented in ppm, 1-1000000
    1/3 corresponds to y= multiple * x^2
    1/2 corresponds to y= multiple * x
    2/3 corresponds to y= multiple * x^1/2
    multiple will depends on contract initialization,
    specificallytotalAmount and poolBalance parameters
    we might want to add an 'initialize' function that will allow
    the owner to send ether to the contract and mint a given amount of tokens
  */
    uint32 reserveRatio;

    /*
    - Front-running attacks are currently mitigated by the following mechanisms:
    TODO - minimum return argument for each conversion provides a way to define a minimum/maximum price for the transaction
    - gas price limit prevents users from having control over the order of execution
  */
    uint256 public gasPrice = 3000000000 wei; // maximum gas price for bancor transactions

    /**
     * @dev receive function
     */
    receive() external payable {
        buy();
    }

    /**
     * @dev default fallback function
     *
     */
    fallback() external payable {
        buy();
    }

    /**
     * @dev buy tokens
     * gas cost 77508
     * @return {bool}
     */
    function buy() public payable returns (bool) {
        console.log("buy started");
        require(msg.value > 0, "value cannot be zero");
        console.log("passed req");
        uint256 tokensToMint = calculatePurchaseReturn(
            totalSupply(),
            poolBalance,
            reserveRatio,
            msg.value
        );
        console.log("passed calc");
        _mint(msg.sender, tokensToMint);
        console.log("passed mint");
        poolBalance = poolBalance + msg.value;
        emit LogMint(tokensToMint, msg.value);
        return true;
    }

    /**
     * @dev sell tokens
     * gase cost 86454
     * @param sellAmount amount of tokens to withdraw
     * @return {bool}
     */
    function sell(uint256 sellAmount) public validGasPrice returns (bool) {
        require(sellAmount > 0 && balanceOf(msg.sender) >= sellAmount);
        uint256 ethAmount = calculateSaleReturn(
            totalSupply(),
            poolBalance,
            reserveRatio,
            sellAmount
        );
        payable(msg.sender).transfer(ethAmount);
        poolBalance = poolBalance - ethAmount;
        _burn(msg.sender, ethAmount);
        emit LogWithdraw(sellAmount, ethAmount);
        return true;
    }

    // verifies that the gas price is lower than the universal limit
    modifier validGasPrice() {
        require(tx.gasprice <= gasPrice, "gas price req failed");
        _;
    }

    /**
     *  @dev allows the owner to update the gas price limit
     *  @param _gasPrice    new gas price limit
     */
    function setGasPrice(uint256 _gasPrice) public onlyOwner {
        require(_gasPrice > 0, "Gas price cannot be 0");
        gasPrice = _gasPrice;
    }

    event LogMint(uint256 amountMinted, uint256 totalCost);
    event LogWithdraw(uint256 amountWithdrawn, uint256 reward);
    event LogBondingCurve(string logString, uint256 value);
}

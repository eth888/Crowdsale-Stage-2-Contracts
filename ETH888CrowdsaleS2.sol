pragma solidity ^0.4.11;

import './VanilCoin.sol';
import 'zeppelin-solidity/contracts/token/MintableToken.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';

contract ETH888CrowdsaleS2 {

	using SafeMath for uint256;
	
	// The token being sold
	address public vanilAddress;
	VanilCoin public vanilCoin;
	
	// address where funds are collected
	address public wallet;
	
	// how many token units a buyer gets per wei
	uint256 public rate = 1000;
	
	// timestamps for ICO starts and ends
	uint public startTimestamp;
	uint public endTimestamp;
	
	// amount of raised money in wei
	uint256 public weiRaised;
	
	mapping(uint8 => uint64) public rates;
	// week 2, 28 April 2018, 000:00:00 GMT
	uint public timeTier1 = 1524873600;
	// week 3, 5 May 2018, 000:00:00 GMT
	uint public timeTier2 = 1525478400;
	// week 4, 12 May 2018, 000:00:00 GMT
	uint public timeTier3 = 1526083200;

	/**
	   * event for token purchase logging
	   * @param purchaser who paid for the tokens
	   * @param beneficiary who got the tokens
	   * @param value weis paid for purchase
	   * @param amount amount of tokens purchased
	   */ 
	event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

	function ETH888CrowdsaleS2(address _wallet, address _vanilAddress) {
		
		require(_wallet != 0x0 && _vanilAddress != 0x0);
		
		// 21 April 2018, 00:00:00 GMT: 1524268800
		startTimestamp = 1524268800;
		
		// 21 May 2018, 00:00:00 GMT: 1526860800
		endTimestamp = 1526860800;
		
		rates[0] = 400;
		rates[1] = 300;
		rates[2] = 200;
		rates[3] = 100;

		wallet = _wallet;
		vanilAddress = _vanilAddress;
		vanilCoin = VanilCoin(vanilAddress);
	}
		
	// fallback function can be used to buy tokens
	function () payable {
	    buyTokens(msg.sender);
	}
	
	// low level token purchase function
	function buyTokens(address beneficiary) payable {
		require(beneficiary != 0x0 && validPurchase() && validAmount());

		if(now < timeTier1)
			rate = rates[0];
		else if(now < timeTier2)
			rate = rates[1];
		else if(now < timeTier3)
			rate = rates[2];
		else
			rate = rates[3];

		uint256 weiAmount = msg.value;
		uint256 tokens = weiAmount.mul(rate);

		// update state
		weiRaised = weiRaised.add(weiAmount);
		vanilCoin.transfer(beneficiary, tokens);

		TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

		forwardFunds();
	}

	function totalSupply() public constant returns (uint)
	{
		return vanilCoin.totalSupply();
	}

	function vanilAddress() public constant returns (address)
	{
		return vanilAddress;
	}

	// send ether to the fund collection wallet
	function forwardFunds() internal {
		wallet.transfer(msg.value);
	}	
	
	function validAmount() internal constant returns (bool)
	{
		uint256 weiAmount = msg.value;
		uint256 tokens = weiAmount.mul(rate);

		return (vanilCoin.balanceOf(this) >= tokens);
	}

	// @return true if investors can buy at the moment
	function validPurchase() internal constant returns (bool) {
		
		uint current = now;
		bool withinPeriod = current >= startTimestamp && current <= endTimestamp;
		bool nonZeroPurchase = msg.value != 0;
		
		return withinPeriod && nonZeroPurchase && msg.value >= 1000 szabo;
	}

	// @return true if crowdsale event has ended
	function hasEnded() public constant returns (bool) {
		
		return now > endTimestamp;
	}
	
}
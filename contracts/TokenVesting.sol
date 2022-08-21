// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenVesting is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public vestingToken;

    uint256 public constant PRECISION = 10 ** 12;

    mapping (address => uint256) public startTime;

    mapping (address => uint256) public duration;

    mapping (address => uint256) public cliffDuration;

    mapping (address => uint256) public claimed;

    mapping (address => uint256) public claimable;

    event Claimed(address user, uint256 amount);

    constructor(IERC20 _vestingToken) {
        vestingToken = _vestingToken;
    }

    function addVesting(address _user, uint256 _amount, uint256 _startTime, uint256 _duration, uint256 _cliffDuration) external onlyOwner {
        require(_startTime > block.timestamp, "TokenVesting: invalid start time");
        require(_duration > 0, "TokenVesting: invalid duration");
        require(_cliffDuration > 0 && _cliffDuration < _duration, "TokenVesting: invalid cliff duration");

        claimable[_user] = _amount;
        startTime[_user] = _startTime;
        duration[_user] = _duration;
        cliffDuration[_user] = _cliffDuration;
    }

    function claim() external {
        require(claimable[msg.sender] > 0, "TokenVesting: no claimable tokens");
        require(block.timestamp >= startTime[msg.sender] + cliffDuration[msg.sender], "TokenVesting: cliff period has not passed");
        uint256 claimDuration = block.timestamp > startTime[msg.sender] + duration[msg.sender] ? duration[msg.sender] : block.timestamp - startTime[msg.sender];
        uint256 amount = claimable[msg.sender] * (claimDuration * PRECISION / duration[msg.sender]) / PRECISION - claimed[msg.sender];
        require(amount > 0, "TokenVesting: no claimable tokens");
        claimed[msg.sender] += amount;

        vestingToken.approve(address(this), amount);

        vestingToken.safeTransferFrom(
            address(this),
            msg.sender,
            amount
        );

        emit Claimed(msg.sender, amount);
    }
}

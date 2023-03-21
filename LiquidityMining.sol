pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract LiquidityMining {
    IERC20 public token;  // 代币合约
    IERC20 public lpToken;  // 流动性代币合约
    address public owner;  // 合约拥有者
    uint256 public rewardPerBlock;  // 每个块的奖励
    uint256 public lastUpdateTime;  // 上次更新时间
    uint256 public rewardPerTokenStored;  // 存储的每个代币的奖励
    mapping(address => uint256) public rewardPerTokenPaid;  // 每个账户的每个代币的奖励已支付
    mapping(address => uint256) public rewards;  // 每个账户获得的奖励

    event RewardPaid(address indexed user, uint256 reward);

    constructor(IERC20 _token, IERC20 _lpToken, uint256 _rewardPerBlock) {
        token = _token;
        lpToken = _lpToken;
        rewardPerBlock = _rewardPerBlock;
        owner = msg.sender;
        lastUpdateTime = block.timestamp;
    }

    function setRewardPerBlock(uint256 _rewardPerBlock) external {
        require(msg.sender == owner, "Only the owner can call this function.");
        updateRewardPerToken();
        rewardPerBlock = _rewardPerBlock;
        lastUpdateTime = block.timestamp;
    }

    function deposit(uint256 amount) external {
        updateRewardPerToken();
        lpToken.transferFrom(msg.sender, address(this), amount);
        rewards[msg.sender] += earned(msg.sender);
        rewardPerTokenPaid[msg.sender] = rewardPerTokenStored;
    }

    function withdraw(uint256 amount) external {
        updateRewardPerToken();
        rewards[msg.sender] += earned(msg.sender);
        rewardPerTokenPaid[msg.sender] = rewardPerTokenStored;
        lpToken.transfer(msg.sender, amount);
    }

    function getReward() external {
        updateRewardPerToken();
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards to claim");
        rewards[msg.sender] = 0;
        token.transfer(msg.sender, reward);
        emit RewardPaid(msg.sender, reward);
    }

    function earned(address account) public view returns (uint256) {
        uint256 totalSupply = lpToken.balanceOf(address(this));
        uint256 rewardPerToken = rewardPerToken();
        uint256 reward = (totalSupply == 0) ? 0 : (rewardPerToken - rewardPerTokenPaid[account]) * lpToken.balanceOf(account) / 1e18;
        return rewards[account] + reward;
    }

    function rewardPerToken() public view returns (uint256) {
        if (lpToken.balanceOf(address(this)) == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + (block.timestamp - lastUpdateTime) * rewardPerBlock * 1e18 / lpToken.balanceOf(address(this));
    }

    function updateRewardPerToken() internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
    }
}

pragma solidity ^0.5;

import "./Auction.sol";
import "./ERC20.sol";

library FactoryAddress {}
library USD {}
library DSF {}

interface Factory {
    function getTokenName(bool isCall, uint256 expiration, uint256 strike) external returns (string memory);
    function getTokenSymbol(bool isCall, uint256 expiration, uint256 strike) external returns (string memory);
}


contract OptionToken is ERC20 {
    bool public initialized;
    // address public factory;

    uint256 public expiration;
    uint256 public strike;

    mapping(address => mapping(address => uint256)) public receivals;
    mapping(address => uint256) public writers;
    mapping(address => mapping(address => uint256)) public writerAllowance;
    mapping(address => mapping(address => uint256)) public writerReceivals;

    uint256 public exercised;
    uint256 public written;
    uint256 public assigned;
    uint256 public settled;

    uint256 public constant SETTLEMENT_DURATION = 12 hours;

    event WriterTransfer(address indexed _from, address indexed _to, uint256 _value);
    event WriterApproval(address indexed _owner, address indexed _spender, uint256 _value);

    // called by Factory in same transaction as deploy
    function init(
        uint256 _expiration,
        uint256 _strike
    ) public returns (bool) {
        require(initialized == false);
        expiration = _expiration;
        strike = _strike;
        initialized = true;
        return true;
    }

    function dsf() public pure returns (ERC20) {
        return ERC20(address(DSF));
    }

    function usd() public pure returns (ERC20) {
        return ERC20(address(USD));
    }

    function receiveAndCall(address receiver, uint256 quantity, bytes memory data) public returns (bool) {
        receivals[msg.sender][receiver] = quantity;
        (bool result,) = receiver.call(data);
        receivals[msg.sender][receiver] = 0;
        require(result);
        return true;
    }

    function receiveFrom(address from, address to, uint256 quantity) public returns (bool) {
        require(receivals[from][msg.sender] >= quantity && balances[from] >= quantity);
        balances[from] -= quantity;
        receivals[from][msg.sender] -= quantity;
        balances[to] += quantity;
        emit Transfer(from, to, quantity);
    }

    function writerApprove(address _spender, uint256 _value) public returns (bool success) {
        writerAllowance[msg.sender][_spender] = _value;
        emit WriterApproval(msg.sender, _spender, _value);
        return true;
    }

    function writerTransfer(address to, uint256 amount) public returns (bool) {
        require(writers[msg.sender] >= amount);
        writers[msg.sender] -= amount;
        writers[to] += amount;
        emit WriterTransfer(msg.sender, to, amount);
        return true;
    }

    function writerTransferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(writers[from] >= amount && writerAllowance[from][msg.sender] >= amount);
        writers[from] -= amount;
        writerAllowance[from][from] -= amount;
        writers[to] += amount;
        emit WriterTransfer(from, to, amount);
        return true;
    }

    function writerReceiveAndCall(address receiver, uint256 quantity, bytes memory data) public returns (bool) {
        writerReceivals[msg.sender][receiver] = quantity;
        (bool result,) = receiver.call(data);
        writerReceivals[msg.sender][receiver] = 0;
        require(result);
        return true;
    }

    function writerReceiveFrom(address from, address to, uint256 quantity) public returns (bool) {
        require(writerReceivals[from][msg.sender] >= quantity && balances[from] >= quantity);
        balances[from] -= quantity;
        writerReceivals[from][msg.sender] -= quantity;
        balances[to] += quantity;
        emit WriterTransfer(from, to, quantity);
    }

    function edge(address account) public view returns (uint256) {
        return 0.03 ether - 1 ether * 1 ether / (dsf().balanceOf(account) + 33.333333333333333333 ether);
    }

    function settlementStart() public view returns (uint256) {
        return expiration;
    }

    function settlementEnd() public view returns (uint256) {
        return expiration + SETTLEMENT_DURATION;
    }
}
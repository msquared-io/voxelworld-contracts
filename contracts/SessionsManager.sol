// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SessionsManager {
    struct SessionPermission {
        address user;            // User's EOA address (20 bytes)
        uint32 startTime;        // Session start timestamp (4 bytes)
        uint32 expiryTime;       // Session expiration timestamp (4 bytes)
        uint256 sessionId;       // Hash-based session identifier
        // Above fields fit in a single 32-byte slot
        uint256 balance;         // Current active balance of ETH for the session
        // Arrays use separate storage slots
        address[] allowedContracts;
        bytes4[] allowedFunctions;
        address[] authorizedExecutors;
    }
    
    mapping(uint256 => SessionPermission) public sessions;
        
    // Events
    event SessionCreated(address indexed user, uint256 indexed sessionId, uint256 initialBalance, uint32 expiryTime);
    event SessionTopUp(address indexed user, uint256 indexed sessionId, uint256 amount, uint256 newBalance);
    event SessionWithdrawal(address indexed user, uint256 indexed sessionId, uint256 amount, uint256 newBalance);
    event SessionRevoked(address indexed user, uint256 indexed sessionId, uint256 refundAmount);
    event ExecutorAdded(address indexed user, uint256 indexed sessionId, address executor);

    // Helper function to generate session ID hash
    function generateSessionId(
        address user,
        address[] calldata authorizedExecutors,
        address[] calldata allowedContracts,
        bytes4[] calldata allowedFunctions
    ) public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            user,
            address(this),
            keccak256(abi.encodePacked(authorizedExecutors)),
            keccak256(abi.encodePacked(allowedContracts)),
            keccak256(abi.encodePacked(allowedFunctions))
        )));
    }
    
    // Create a session with an initial balance
    // If allowedContracts is empty, all contracts are allowed
    // If allowedFunctions is empty, all functions are allowed for the allowed contracts
    function createSession(
        uint32 expiryTime,
        address[] calldata allowedContracts,
        bytes4[] calldata allowedFunctions,
        address[] calldata authorizedExecutors
    ) external payable {
        // Only require equal lengths if both arrays have elements
        if (allowedContracts.length > 0 && allowedFunctions.length > 0) {
            require(allowedContracts.length == allowedFunctions.length, "Arrays must have same length");
        }
        
        // Optimization 3: Cache values to reduce storage reads/writes
        address user = msg.sender;
        
        // Generate session ID by hashing the relevant inputs
        uint256 sessionId = generateSessionId(user, authorizedExecutors, allowedContracts, allowedFunctions);
        
        // Optimization: Direct storage initialization
        SessionPermission storage permission = sessions[sessionId];
        permission.user = user;
        permission.startTime = uint32(block.timestamp);
        permission.expiryTime = expiryTime;
        permission.balance = msg.value;
        permission.sessionId = sessionId;
        
        // Optimization: More efficient loops using uint256 for gas efficiency
        uint256 contractsLength = allowedContracts.length;
        uint256 functionsLength = allowedFunctions.length;
        uint256 executorsLength = authorizedExecutors.length;
        
        // Store allowed contracts
        for (uint256 i; i < contractsLength; ++i) {
            permission.allowedContracts.push(allowedContracts[i]);
        }
        
        // Store allowed functions
        for (uint256 i; i < functionsLength; ++i) {
            permission.allowedFunctions.push(allowedFunctions[i]);
        }
        
        // Store authorized executors
        for (uint256 i; i < executorsLength; ++i) {
            permission.authorizedExecutors.push(authorizedExecutors[i]);
            emit ExecutorAdded(user, sessionId, authorizedExecutors[i]);
        }
        
        emit SessionCreated(user, sessionId, msg.value, expiryTime);
    }
    
    // Add more funds to an existing session
    function topUpSession(uint256 sessionId) external payable {
        require(msg.value > 0, "Top-up amount must be greater than zero");
        
        // Optimization: Cache msg.sender to reduce gas
        address user = msg.sender;
        
        SessionPermission storage session = sessions[sessionId];
        require(session.user == user, "Session not found");
        require(session.expiryTime == 0 || block.timestamp <= session.expiryTime, "Session expired");
        
        // Optimization: Direct update instead of creating a temp variable
        session.balance += msg.value;
        
        emit SessionTopUp(user, sessionId, msg.value, session.balance);
    }
    
    // Withdraw funds from a session
    function withdrawFromSession(uint256 sessionId, uint256 amount) external {
        require(amount > 0, "Withdrawal amount must be greater than zero");
        
        // Optimization: Cache msg.sender
        address user = msg.sender;
        
        SessionPermission storage session = sessions[sessionId];
        require(session.user == user, "Session not found");
        require(amount <= session.balance, "Insufficient balance");
        
        // Decrease session balance (follow checks-effects-interactions pattern)
        session.balance -= amount;
        
        // Transfer ETH to the user
        (bool success, ) = user.call{value: amount}("");
        require(success, "Withdrawal failed");
        
        emit SessionWithdrawal(user, sessionId, amount, session.balance);
    }
    
    // Add a new authorized executor to an existing session
    function addAuthorizedExecutor(uint256 sessionId, address executor) external {
        // Optimization: Cache msg.sender
        address user = msg.sender;
        
        SessionPermission storage session = sessions[sessionId];
        require(session.user == user, "Session not found");
        require(session.expiryTime == 0 || block.timestamp <= session.expiryTime, "Session expired");
        
        // Check if executor is already authorized
        address[] storage authorizedExecutors = session.authorizedExecutors;
        uint256 length = authorizedExecutors.length;
        
        for (uint256 i; i < length; ++i) {
            if (authorizedExecutors[i] == executor) {
                return; // Executor already authorized, do nothing
            }
        }
        
        // Add new executor
        authorizedExecutors.push(executor);
        emit ExecutorAdded(user, sessionId, executor);
    }
    
    // Check if a specific address is authorized to execute transactions for a session
    function isAuthorizedExecutor(address user, uint256 sessionId, address executor) public view returns (bool) {
        // Optimization: Early return for common case
        if (executor == user) return true; // User is always authorized for their own session
        
        // Get authorized executors array from storage
        address[] storage authorizedExecutors = sessions[sessionId].authorizedExecutors;
        uint256 length = authorizedExecutors.length;
        
        // Check if executor is in the authorized list
        for (uint256 i; i < length; ++i) {
            if (authorizedExecutors[i] == executor) {
                return true;
            }
        }
        
        return false;
    }
    
    // Helper function to check if a contract/function pair is allowed
    function isCallAllowed(
        uint256 sessionId, 
        address target, 
        bytes4 selector
    ) public view returns (bool) {
        SessionPermission storage session = sessions[sessionId];
        
        // Cache array lengths to avoid multiple storage reads
        uint256 contractsLength = session.allowedContracts.length;
        uint256 functionsLength = session.allowedFunctions.length;
        
        // Fast path checks with most likely conditions first
        if (contractsLength == 0) {
            // If allowedContracts is empty, all contracts are allowed
            if (functionsLength == 0) {
                return true; // Both arrays empty means everything is allowed
            }
            
            // Check if the function is in the allowed list
            for (uint256 i; i < functionsLength; ++i) {
                if (session.allowedFunctions[i] == selector) {
                    return true;
                }
            }
            return false;
        }
        
        // If allowedFunctions is empty, all functions are allowed for the allowed contracts
        if (functionsLength == 0) {
            for (uint256 i; i < contractsLength; ++i) {
                if (session.allowedContracts[i] == target) {
                    return true;
                }
            }
            return false;
        }
        
        // Both arrays have entries, check for specific contract/function pairs
        for (uint256 i; i < contractsLength; ++i) {
            if (session.allowedContracts[i] == target && session.allowedFunctions[i] == selector) {
                return true;
            }
        }
        
        return false;
    }
    
    // Execute a transaction on behalf of a user
    function executeOnBehalf(
        address user,
        uint256 sessionId,
        address target,
        uint256 value,
        bytes calldata data
    ) external returns (bytes memory) {
        SessionPermission storage session = sessions[sessionId];
        
        // Optimization: Group validation checks
        require(session.user == user, "Session not found");
        require(session.expiryTime == 0 || block.timestamp <= session.expiryTime, "Session expired");
        require(isAuthorizedExecutor(user, sessionId, msg.sender), "Not authorized to execute");
        
        // Check if there's enough balance left
        require(value <= session.balance, "Insufficient balance");
        
        // Verify target contract and function are allowed
        bytes4 selector = bytes4(data[:4]);
        require(isCallAllowed(sessionId, target, selector), "Target or function not allowed");
        
        // Decrease session balance before call (checks-effects-interactions pattern)
        if (value > 0) {
            session.balance -= value;
        }
        
        // Execute the call
        (bool success, bytes memory returnData) = target.call{value: value}(
            abi.encodePacked(data, user) // Append user address to data
        );
        require(success, "Transaction failed");
        
        return returnData;
    }
    
    // Get allowed contracts and functions for a session
    function getSessionAllowList(
        address user, 
        uint256 sessionId
    ) external view returns (address[] memory contracts, bytes4[] memory functions) {
        SessionPermission storage session = sessions[sessionId];
        require(session.user == user, "Session not found");
        
        return (session.allowedContracts, session.allowedFunctions);
    }

    // Get authorized executors for a session
    function getAuthorizedExecutors(
        address user, 
        uint256 sessionId
    ) external view returns (address[] memory) {
        SessionPermission storage session = sessions[sessionId];
        require(session.user == user, "Session not found");
        
        return session.authorizedExecutors;
    }
    
    // Get session balance
    function getBalance(address user, uint256 sessionId) external view returns (uint256) {
        SessionPermission storage session = sessions[sessionId];
        if (session.user != user) return 0;
        
        return session.balance;
    }
    
    // Revoke a session and refund remaining balance
    function revokeSession(uint256 sessionId) external {
        // Optimization: Cache msg.sender
        address user = msg.sender;
        
        SessionPermission storage session = sessions[sessionId];
        require(session.user == user, "Session not found");
        
        // Get remaining balance for refund
        uint256 refundAmount = session.balance;
        
        // Delete session before sending ETH to prevent reentrancy attacks
        delete sessions[sessionId];
        
        // Refund unused balance
        if (refundAmount > 0) {
            (bool success, ) = user.call{value: refundAmount}("");
            require(success, "Refund failed");
        }
        
        emit SessionRevoked(user, sessionId, refundAmount);
    }

    function getSession(address user, address[] calldata authorizedExecutors, address[] calldata allowedContracts, bytes4[] calldata allowedFunctions) external view returns (SessionPermission memory) {
        uint256 sessionId = generateSessionId(user, authorizedExecutors, allowedContracts, allowedFunctions);
        SessionPermission memory session = sessions[sessionId];

        if (session.expiryTime > 0 && block.timestamp > session.expiryTime) {
            return SessionPermission({
                user: address(0),
                startTime: 0,
                expiryTime: 0,
                sessionId: 0,
                balance: 0,
                allowedContracts: new address[](0),
                allowedFunctions: new bytes4[](0),
                authorizedExecutors: new address[](0)
            });
        }
        
        return session;
    }
}
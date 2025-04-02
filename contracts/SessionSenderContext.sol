// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
error NotOwner();

// we have to inherit so we can override??
abstract contract SessionSenderContext is Context, Ownable {
    address public sessionManager;
    
    constructor(address _sessionManager) Ownable(_msgSender()) {
        sessionManager = _sessionManager;
    }
    
    function _msgSender() internal view virtual override returns (address) {
        if (msg.sender == sessionManager) {
            address sender;
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
            return sender;
        } else {
            return msg.sender;
        }
    }

    function updateSessionManager(address _sessionManager) internal onlyOwner {
        sessionManager = _sessionManager;
    }
}

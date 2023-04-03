// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../../openzeppelin/upgradeable/ContextUpgradeable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract SelectorPausableUpgradeable is ContextUpgradeable {
    // Allocating __gap for futhur variable (need to subtract equal to new state added)
    uint256[10] private __gap_top_selectorPausable;

    /**
     * @dev Emitted when the pause is triggered by `account` and `function selector`.
     */
    event Paused(address account, bytes4 functionSelector);

    /**
     * @dev Emitted when the pause is lifted by `account` and `function selector`.
     */
    event Unpaused(address account, bytes4 functionSelector);

    mapping(bytes4 => bool) private _isPaused;

    uint256[10] private __gap_bottom_selectorPausable;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        //_isPaused = false;
    }

    /**
     * @dev Returns true if the function selected is paused, and false otherwise.
     */
    function isPaused(bytes4 _func) public view virtual returns (bool) {
        return _isPaused[_func];
    }

    /**
     * @dev Modifier to make a function callable only when the function selected is not paused.
     *
     * Requirements:
     *
     * - The function selected must not be paused.
     */
    modifier whenFuncNotPaused(bytes4 _func) {
        require(!_isPaused[_func], "Pausable/function-is-paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the function selected is paused.
     *
     * Requirements:
     *
     * - The function selected must be paused.
     */
    modifier whenFuncPaused(bytes4 _func) {
        require(_isPaused[_func], "Pausable/function-is-not-paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The function selected must not be paused.
     */
    function _pause(bytes4 _func) internal virtual whenFuncNotPaused(_func) {
        _isPaused[_func] = true;
        emit Paused(_msgSender(), _func);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The function selected must be paused.
     */
    function _unpause(bytes4 _func) internal virtual whenFuncPaused(_func) {
        _isPaused[_func] = false;
        emit Unpaused(_msgSender(), _func);
    }
}

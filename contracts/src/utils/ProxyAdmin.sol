// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract ProxyAdminContract is ProxyAdmin {
    constructor() payable ProxyAdmin() {}
}

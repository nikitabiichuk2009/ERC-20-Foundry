// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {NikitaBiichuk} from "../src/OurToken.sol";

contract DeployOurToken is Script {
    function run() external returns (NikitaBiichuk) {
        vm.startBroadcast();
        NikitaBiichuk token = new NikitaBiichuk(msg.sender);
        vm.stopBroadcast();
        return token;
    }
}

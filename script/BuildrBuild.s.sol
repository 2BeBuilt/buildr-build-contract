// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import "../src/BuildrBuild_v4.sol";

contract MyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        new BuildrBuild(
            "buildr.build", //change name buildr.build
            "buildr", //change symbol buildr
            "ipfs://bafybeifc7cjhbck7dutol6gfoyozxlqgbzlhyyc4isksno7tiymzvprhx4/" //Actual ipfs://bafybeifc7cjhbck7dutol6gfoyozxlqgbzlhyyc4isksno7tiymzvprhx4/
        );

        vm.stopBroadcast();
    }
}

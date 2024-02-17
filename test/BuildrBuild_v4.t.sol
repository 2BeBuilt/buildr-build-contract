// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "lib/forge-std/src/Test.sol";
import "src/BuildrBuild_v4.sol";

contract BuildrBuildTest is Test {
    BuildrBuild buildr;

    address public deployer = 0xF1A5d276DEDc2eD82eaa69B37062Ef2BA1F04bBf;
    address public pranker = address(0x1);

    function setUp() public {
        vm.startPrank(deployer, deployer);
        vm.deal(deployer, 10 ether);

        buildr = new BuildrBuild(
            "buildr.build",
            "buildr",
            "ipfs://bafybeifc7cjhbck7dutol6gfoyozxlqgbzlhyyc4isksno7tiymzvprhx4/"
        );
        vm.stopPrank();
        vm.startPrank(address(0x1), address(0x1));
        vm.deal(address(0x1), 10 ether);
    }

    function test_values() public {
        assertEq(
            buildr.baseURI(),
            "ipfs://bafybeifc7cjhbck7dutol6gfoyozxlqgbzlhyyc4isksno7tiymzvprhx4/"
        );
        assertEq(
            buildr.tokenURI(1),
            "ipfs://bafybeifc7cjhbck7dutol6gfoyozxlqgbzlhyyc4isksno7tiymzvprhx4/1.json"
        );
        assertEq(buildr.getBuildr(), deployer);
        assertEq(buildr.getInfraCosts(), 0.005 ether);
        assertEq(buildr.totalSupply(), 4024);
    }

    function test_mintBuildrRevert() public {
        vm.expectRevert(TransferFailed.selector);
        buildr.mintBuildr(1);
    }

    function test_mintBuildrRevertRangeUnder() public {
        uint256 val = buildr.getInfraCosts();
        vm.expectRevert(FixTokenId.selector);
        buildr.mintBuildr{value: val}(0);
    }

    function test_mintBuildrRevertRangeOver() public {
        uint256 val = buildr.getInfraCosts();
        vm.expectRevert(FixTokenId.selector);
        buildr.mintBuildr{value: val}(4025);
    }

    function test_mintBuildr() public {
        buildr.mintBuildr{value: buildr.getInfraCosts()}(1);
        assertEq(buildr.balanceOf(pranker), 1);
    }

    function test_mapChangeNotOwner() public {
        buildr.mintBuildr{value: buildr.getInfraCosts()}(1);
        vm.stopPrank();
        vm.startPrank(deployer, deployer);
        buildr.mintBuildr{value: buildr.getInfraCosts()}(2);
        vm.expectRevert(NotTokenOwner.selector);
        buildr.mapChange(1, 2);
        assertEq(buildr.balanceOf(address(0x1)), 1);
        assertEq(buildr.balanceOf(deployer), 1);
        assertEq(buildr.ownerOf(1), address(0x1));
        assertEq(buildr.ownerOf(2), deployer);
    }

    function test_mapChangeNotOwnerReversed() public {
        buildr.mintBuildr{value: buildr.getInfraCosts()}(1);
        vm.stopPrank();
        vm.startPrank(deployer, deployer);
        buildr.mintBuildr{value: buildr.getInfraCosts()}(2);
        vm.expectRevert(NotTokenOwner.selector);
        buildr.mapChange(2, 1);
        assertEq(buildr.balanceOf(address(0x1)), 1);
        assertEq(buildr.balanceOf(deployer), 1);
        assertEq(buildr.ownerOf(1), address(0x1));
        assertEq(buildr.ownerOf(2), deployer);
    }

    function test_mapChange() public {
        buildr.mintBuildr{value: buildr.getInfraCosts()}(1);
        buildr.mintBuildr{value: buildr.getInfraCosts()}(2);
        buildr.mapChange(1, 2);
        vm.expectRevert("NOT_MINTED");
        buildr.ownerOf(2);
        assertEq(buildr.balanceOf(address(0x1)), 1);
        assertEq(buildr.getBuildrInfo(2), "");
    }

    function test_withdrawETH() public {
        uint256 val = deployer.balance;
        buildr.mintBuildr{value: buildr.getInfraCosts()}(1);
        buildr.withdrawETH();
        assertEq(val + buildr.getInfraCosts(), deployer.balance);
    }

    function test_editContactInfo() public {
        buildr.mintBuildr{value: buildr.getInfraCosts()}(1);
        vm.stopPrank();
        vm.startPrank(deployer, deployer);
        buildr.mintBuildr{value: buildr.getInfraCosts()}(2);
        vm.expectRevert(NotTokenOwner.selector);
        buildr.editBuildrInfo(
            "ipfs://bafybeifc7cjhbck7dutol6gfoyozxlqgbzlhyyc4isksno7tiymzvprhx4",
            1
        );
        buildr.editBuildrInfo(
            "ipfs://bafybeifc7cjhbck7dutol6gfoyozxlqgbzlhyyc4isksno7tiymzvprhx4",
            2
        );
        assertEq(
            buildr.getBuildrInfo(2),
            "ipfs://bafybeifc7cjhbck7dutol6gfoyozxlqgbzlhyyc4isksno7tiymzvprhx4"
        );
    }

    function test_transferBurns() public {
        buildr.mintBuildr{value: buildr.getInfraCosts()}(1);
        buildr.transferFrom(address(0x1), deployer, 1);
        assertEq(buildr.getBuildrInfo(1), "");
        vm.expectRevert("WRONG_FROM");
        buildr.transferFrom(address(0x1), deployer, 1);
        assertEq(buildr.ownerOf(1), deployer);
    }

    function test_fundAndWithdraw(uint256 _amount) public {
        vm.assume(_amount < 1e75);
        vm.deal(pranker, _amount * 2);
        (bool success, ) = address(buildr).call{value: _amount}("");
        if (!success) {
            revert();
        }
        buildr.fundBuildr{value: _amount}(1, BuildrBuild.Web3District(2));
        uint256 val = deployer.balance;
        buildr.withdrawETH();
        assertEq(val + (_amount * 2), deployer.balance);
    }

    function test_fundBuildr(uint256 _amount) public {
        vm.deal(pranker, _amount);
        vm.assume(_amount < 1e75);

        buildr.fundBuildr{value: _amount}(1, BuildrBuild.Web3District(2));
        uint256 val = deployer.balance;
        buildr.withdrawETH();
        assertEq(val + _amount, deployer.balance);
        assertEq(
            buildr.getBuildrDistrictBalance(1, BuildrBuild.Web3District(2)),
            _amount
        );
    }

    function test_fundBuildrTotalBalance(uint256 _amount) public {
        vm.assume(_amount < 1e75);
        vm.deal(pranker, _amount * 5);

        buildr.fundBuildr{value: _amount}(100, BuildrBuild.Web3District(0));
        buildr.fundBuildr{value: _amount}(100, BuildrBuild.Web3District(1));
        buildr.fundBuildr{value: _amount}(100, BuildrBuild.Web3District(2));
        buildr.fundBuildr{value: _amount}(100, BuildrBuild.Web3District(3));
        buildr.fundBuildr{value: _amount}(100, BuildrBuild.Web3District(4));
        uint256 val = deployer.balance;
        buildr.withdrawETH();
        assertEq(val + (_amount * 5), deployer.balance);
        assertEq(buildr.getBuildrTotalBalance(100), _amount * 5);
        assertEq(
            buildr.getBuildrDistrictBalance(1, BuildrBuild.Web3District(0)),
            0
        );
        assertEq(
            buildr.getBuildrDistrictBalance(100, BuildrBuild.Web3District(1)),
            _amount
        );
        assertEq(
            buildr.getBuildrDistrictBalance(100, BuildrBuild.Web3District(2)),
            _amount
        );
        assertEq(
            buildr.getBuildrDistrictBalance(100, BuildrBuild.Web3District(3)),
            _amount
        );
        assertEq(
            buildr.getBuildrDistrictBalance(100, BuildrBuild.Web3District(4)),
            _amount
        );
    }

    function test_editAllDetails_v2() public {
        vm.expectRevert("NOT_MINTED");
        buildr.editAllDetails_v2(
            BuildrBuild.Web3District(4),
            1,
            "ipfs://bafybeifc7cjhbck7dutol6gfoyozxlqgbzlhyyc4isksno7tiymzvprhx4"
        );

        buildr.mintBuildr{value: buildr.getInfraCosts()}(5);
        buildr.editAllDetails_v2(
            BuildrBuild.Web3District(4),
            5,
            "ipfs://bafybeifc7cjhbck7dutol6gfoyozxlqgbzlhyyc4isksno7tiymzvprhx4"
        );
        assertEq(
            buildr.getBuildrInfo(5),
            "ipfs://bafybeifc7cjhbck7dutol6gfoyozxlqgbzlhyyc4isksno7tiymzvprhx4"
        );
        assertEq(buildr.getBuildrTotalBalance(5), 0);
        assertEq(uint256(buildr.getDistrict(5)), 4);
    }

    function test_editBuildrInfo() public {
        vm.expectRevert("NOT_MINTED");
        buildr.editBuildrInfo(
            "ipfs://bafybeifc7cjhbck7dutol6gfoyozxlqgbzlhyyc4isksno7tiymzvprhx4",
            1
        );

        buildr.mintBuildr{value: buildr.getInfraCosts()}(5);
        buildr.editBuildrInfo(
            "ipfs://bafybeifc7cjhbck7dutol6gfoyozxlqgbzlhyyc4isksno7tiymzvprhx4",
            5
        );
        assertEq(
            buildr.getBuildrInfo(5),
            "ipfs://bafybeifc7cjhbck7dutol6gfoyozxlqgbzlhyyc4isksno7tiymzvprhx4"
        );

        assertEq(uint256(buildr.getDistrict(5)), 0);
    }

    function test_editBuildrDistrict() public {
        vm.expectRevert("NOT_MINTED");
        buildr.editBuildrDistrict(BuildrBuild.Web3District(4), 5);

        buildr.mintBuildr{value: buildr.getInfraCosts()}(5);
        buildr.editBuildrDistrict(BuildrBuild.Web3District(2), 5);
        assertEq(buildr.getBuildrInfo(5), "");

        assertEq(uint256(buildr.getDistrict(5)), 2);
    }

    function test_transferResets() public {
        buildr.mintBuildr{value: buildr.getInfraCosts()}(1);
        buildr.editAllDetails_v2(
            BuildrBuild.Web3District(4),
            1,
            "ipfs://bafybeifc7cjhbck7dutol6gfoyozxlqgbzlhyyc4isksno7tiymzvprhx4"
        );
        assertEq(
            buildr.getBuildrInfo(1),
            "ipfs://bafybeifc7cjhbck7dutol6gfoyozxlqgbzlhyyc4isksno7tiymzvprhx4"
        );
        assertEq(buildr.getBuildrTotalBalance(1), 0);
        assertEq(uint256(buildr.getDistrict(1)), 4);

        buildr.transferFrom(address(0x1), deployer, 1);
        assertEq(buildr.getBuildrInfo(1), "");
        vm.expectRevert("WRONG_FROM");
        buildr.transferFrom(address(0x1), deployer, 1);
        assertEq(buildr.ownerOf(1), deployer);
        assertEq(uint256(buildr.getDistrict(1)), 0);
    }
}

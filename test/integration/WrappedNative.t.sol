// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {SafeERC20, IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {Router, IRouter} from 'src/Router.sol';
import {IParam} from 'src/interfaces/IParam.sol';
import {IWrappedNative} from 'src/interfaces/IWrappedNative.sol';

// Test wrapped native
contract WrappedNativeTest is Test {
    using SafeERC20 for IERC20;

    uint256 public constant SIGNER_REFERRAL = 1;
    address public constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    IERC20 public constant WRAPPED_NATIVE = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    uint256 public constant BPS_BASE = 10_000;
    uint256 public constant SKIP = type(uint256).max;

    address public user;
    IRouter public router;

    function setUp() external {
        user = makeAddr('User');
        router = new Router(address(WRAPPED_NATIVE), makeAddr('Pauser'), makeAddr('FeeCollector'));

        // Empty router the balance
        vm.prank(address(router));
        (bool success, ) = payable(address(0)).call{value: address(router).balance}('');
        assertTrue(success);

        vm.label(address(router), 'Router');
        vm.label(address(WRAPPED_NATIVE), 'WrappedNative');
    }

    function testExecuteWrappedNativeDeposit(uint256 amountIn) external {
        amountIn = bound(amountIn, BPS_BASE, WRAPPED_NATIVE.totalSupply());
        address tokenIn = NATIVE;
        IERC20 tokenOut = WRAPPED_NATIVE;
        deal(user, amountIn + 1 ether);

        // Encode logics
        IParam.Logic[] memory logics = new IParam.Logic[](1);
        logics[0] = _logicWrappedNativeDeposit(amountIn, BPS_BASE / 2); // 50% amount

        // Execute
        address[] memory tokensReturn = new address[](2);
        tokensReturn[0] = tokenIn;
        tokensReturn[1] = address(tokenOut);
        vm.prank(user);
        router.execute{value: amountIn}(logics, tokensReturn, SIGNER_REFERRAL);

        address agent = router.getAgent(user);
        assertEq(address(router).balance, 0);
        assertEq(address(agent).balance, 0);
        assertEq(tokenOut.balanceOf(address(router)), 0);
        assertEq(tokenOut.balanceOf(address(agent)), 0);
        assertGt(user.balance, 0);
        assertGt(tokenOut.balanceOf(user), 0);
    }

    function _logicWrappedNativeDeposit(uint256 amountIn, uint256 amountBps) public pure returns (IParam.Logic memory) {
        // Encode inputs
        IParam.Input[] memory inputs = new IParam.Input[](1);
        inputs[0].token = NATIVE;
        inputs[0].amountBps = amountBps;
        if (inputs[0].amountBps == SKIP) inputs[0].amountOrOffset = amountIn;
        else inputs[0].amountOrOffset = SKIP; // data don't have amount parameter

        return
            IParam.Logic(
                address(WRAPPED_NATIVE), // to
                abi.encodeWithSelector(IWrappedNative.deposit.selector),
                inputs,
                IParam.WrapMode.NONE,
                address(0), // approveTo
                address(0) // callback
            );
    }
}

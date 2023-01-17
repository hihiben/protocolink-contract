// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {SafeERC20, IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {Router, IRouter} from '../src/Router.sol';
import {SpenderERC20Approval, ISpenderERC20Approval} from '../src/SpenderERC20Approval.sol';
import {MockERC20} from './mocks/MockERC20.sol';

contract SpenderERC20ApprovalTest is Test {
    using SafeERC20 for IERC20;

    address public user;
    IRouter public router;
    ISpenderERC20Approval public spender;
    IERC20 public mockERC20;

    IRouter.Input[] inputsEmpty;
    IRouter.Output[] outputsEmpty;

    function setUp() external {
        user = makeAddr('User');

        router = new Router();
        spender = new SpenderERC20Approval(address(router));
        mockERC20 = new MockERC20('Mock ERC20', 'mERC20');

        // User approved spender
        vm.startPrank(user);
        mockERC20.safeApprove(address(spender), type(uint256).max);
        vm.stopPrank();

        vm.label(address(router), 'Router');
        vm.label(address(spender), 'SpenderERC20Approval');
        vm.label(address(mockERC20), 'mERC20');
    }

    function testPullToken(uint256 amountIn) external {
        IERC20 tokenIn = mockERC20;
        IERC20 tokenOut = mockERC20;
        amountIn = bound(amountIn, 1e1, 1e12);
        deal(address(tokenIn), user, amountIn);

        // Encode logics
        IRouter.Logic[] memory logics = new IRouter.Logic[](1);
        logics[0] = _logicSpenderERC20Approval(tokenIn, amountIn);

        // Execute
        address[] memory tokensReturn = new address[](1);
        tokensReturn[0] = address(tokenOut);
        vm.prank(user);
        router.execute(logics, tokensReturn);

        assertEq(tokenIn.balanceOf(address(router)), 0);
        assertEq(tokenOut.balanceOf(address(router)), 0);
        assertGt(tokenOut.balanceOf(user), 0);
    }

    // Cannot call spender directly
    function testCannotBeCalledByNonRouter(uint128 amount) external {
        vm.assume(amount > 0);
        deal(address(mockERC20), user, amount);

        vm.startPrank(user);
        vm.expectRevert(ISpenderERC20Approval.InvalidRouter.selector);
        spender.pullToken(address(mockERC20), amount);

        vm.expectRevert(ISpenderERC20Approval.InvalidRouter.selector);
        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        tokens[0] = address(mockERC20);
        amounts[0] = amount;
        spender.pullTokens(tokens, amounts);
        vm.stopPrank();
    }

    function _logicSpenderERC20Approval(IERC20 tokenIn, uint256 amountIn) public view returns (IRouter.Logic memory) {
        return
            IRouter.Logic(
                address(spender), // to
                abi.encodeWithSelector(spender.pullToken.selector, address(tokenIn), amountIn),
                inputsEmpty,
                outputsEmpty,
                address(0) // callback
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

// import {Test, console} from "forge-std/Test.sol";
// import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
// import {Raffle} from "../../src/Raffle.sol";
// import {HelperConfig} from "../../script/HelperConfig.s.sol";
// import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
// import {Vm} from "forge-std/Vm.sol";

// contract RaffleIntegrationTest is Test {
//     Raffle raffle;
//     HelperConfig helperConfig;

//     address player1 = makeAddr("player1");
//     address player2 = makeAddr("player2");

//     event RequestedRaffleWinner(uint256 indexed requestId);

//     function setUp() public {
//         DeployRaffle deployer = new DeployRaffle();
//         (raffle, helperConfig) = deployer.run();

//         vm.deal(player1, 10 ether);
//         vm.deal(player2, 10 ether);
//     }

//     modifier skipFork() {
//         if (block.chainid != 31337) {
//             vm.skip(true);
//         }
//         _;
//     }

//     function testCompleteRaffle() public skipFork {
//         HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

//         uint256 startingPlayer1Balance = player1.balance;
//         uint256 startingPlayer2Balance = player2.balance;

//         // Players enter
//         vm.prank(player1);
//         raffle.enterRaffle{value: config.entranceFee}();

//         vm.prank(player2);
//         raffle.enterRaffle{value: config.entranceFee}();

//         uint256 prizePool = config.entranceFee * 2;

//         // Verify initial state
//         assertEq(uint256(raffle.getRaffleState()), uint256(Raffle.RaffleState.OPEN));
//         assertEq(address(raffle).balance, prizePool);

//         // Time passes
//         vm.warp(block.timestamp + config.interval + 1);
//         vm.roll(block.number + 1);

//         // Record logs BEFORE performUpkeep
//         vm.recordLogs();
//         raffle.performUpkeep(bytes(""));

//         // Verify state changed to CALCULATING
//         assertEq(uint256(raffle.getRaffleState()), uint256(Raffle.RaffleState.CALCULATING));

//         // Get requestId from logs properly
//         Vm.Log[] memory entries = vm.getRecordedLogs();
//         bytes32 requestId = entries[1].topics[1];;

//         assertFalse(requestId == bytes32(0), "RequestId not found in logs");

//         // Fulfill randomness
//         VRFCoordinatorV2_5Mock(config.vrfCoordinator).fulfillRandomWords(
//             uint256(requestId),
//             address(raffle)
//         );

//         // FULL state validation
//         address winner = raffle.getRecentWinner();
//         assertFalse(winner == address(0), "Winner must be set");
//         assertTrue(winner == player1 || winner == player2, "Winner must be one of the players");

//         // State should be OPEN again
//         assertEq(uint256(raffle.getRaffleState()), uint256(Raffle.RaffleState.OPEN));

//         // Prize should be transferred
//         assertEq(address(raffle).balance, 0, "Raffle balance must be zero");

//         // Winner should have received prize
//         uint256 winnerBalance = winner.balance;
//         if (winner == player1) {
//             assertEq(winnerBalance, startingPlayer1Balance - config.entranceFee + prizePool);
//         } else {
//             assertEq(winnerBalance, startingPlayer2Balance - config.entranceFee + prizePool);
//         }

//         // Players array should be cleared
//         vm.expectRevert();
//         raffle.getPlayer(0);

//         // Timestamp should be updated
//         assertEq(raffle.getLastTimeStamp(), block.timestamp);
//     }

//     function testMultiplePlayersEnter() public {
//         HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

//         vm.prank(player1);
//         raffle.enterRaffle{value: config.entranceFee}();

//         vm.prank(player2);
//         raffle.enterRaffle{value: config.entranceFee}();

//         assertEq(raffle.getPlayer(0), player1);
//         assertEq(raffle.getPlayer(1), player2);
//         assertEq(address(raffle).balance, config.entranceFee * 2);
//     }

//     function testMultipleRounds() public skipFork {
//         HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

//         for (uint256 i = 0; i < 3; i++) {
//             // Enter raffle
//             vm.prank(player1);
//             raffle.enterRaffle{value: config.entranceFee}();

//             // Verify entry
//             assertEq(raffle.getPlayer(0), player1);
//             assertEq(address(raffle).balance, config.entranceFee);

//             // Time passes
//             vm.warp(block.timestamp + config.interval + 1);
//             vm.roll(block.number + 1);

//             // Perform upkeep
//             vm.recordLogs();
//             raffle.performUpkeep(bytes(""));

//             // Verify CALCULATING state
//             assertEq(uint256(raffle.getRaffleState()), uint256(Raffle.RaffleState.CALCULATING));

//             // Get requestId
//             Vm.Log[] memory entries = vm.getRecordedLogs();
//             bytes32 requestId = entries[1].topics[1];

//             assertFalse(requestId == bytes32(0), "RequestId not found");

//             // Fulfill random words
//             VRFCoordinatorV2_5Mock(config.vrfCoordinator).fulfillRandomWords(
//                 uint256(requestId),
//                 address(raffle)
//             );

//             // Validate round completed correctly
//             assertEq(raffle.getRecentWinner(), player1, "Player1 should win (only player)");
//             assertEq(uint256(raffle.getRaffleState()), uint256(Raffle.RaffleState.OPEN), "Should be OPEN");
//             assertEq(address(raffle).balance, 0, "Balance should be zero");
//             assertEq(raffle.getLastTimeStamp(), block.timestamp, "Timestamp should update");

//             // Players should be cleared
//             vm.expectRevert();
//             raffle.getPlayer(0);
//         }
//     }

//     // NEGATIVE TESTS

//     function testRevertWhenEnterWithInsufficientETH() public {
//         HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

//         vm.prank(player1);
//         vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
//         raffle.enterRaffle{value: config.entranceFee - 1}();
//     }

//     function testRevertWhenEnterDuringCalculating() public skipFork {
//         HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

//         vm.prank(player1);
//         raffle.enterRaffle{value: config.entranceFee}();

//         vm.warp(block.timestamp + config.interval + 1);
//         vm.roll(block.number + 1);

//         raffle.performUpkeep(bytes(""));

//         // State is CALCULATING now
//         assertEq(uint256(raffle.getRaffleState()), uint256(Raffle.RaffleState.CALCULATING));

//         // Try to enter - should revert
//         vm.prank(player2);
//         vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
//         raffle.enterRaffle{value: config.entranceFee}();
//     }

//     function testRevertPerformUpkeepWhenConditionsNotMet() public {
//         HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

//         // No players, no balance
//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 Raffle.Raffle__UpkeepNotNeeded.selector,
//                 0,
//                 0,
//                 uint256(Raffle.RaffleState.OPEN)
//             )
//         );
//         raffle.performUpkeep(bytes(""));

//         // Has player but not enough time
//         vm.prank(player1);
//         raffle.enterRaffle{value: config.entranceFee}();

//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 Raffle.Raffle__UpkeepNotNeeded.selector,
//                 config.entranceFee,
//                 1,
//                 uint256(Raffle.RaffleState.OPEN)
//             )
//         );
//         raffle.performUpkeep(bytes(""));
//     }

//     function testRevertPerformUpkeepWhenAlreadyCalculating() public skipFork {
//         HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

//         vm.prank(player1);
//         raffle.enterRaffle{value: config.entranceFee}();

//         vm.warp(block.timestamp + config.interval + 1);
//         vm.roll(block.number + 1);

//         raffle.performUpkeep(bytes(""));

//         // Try to call again while CALCULATING
//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 Raffle.Raffle__UpkeepNotNeeded.selector,
//                 config.entranceFee,
//                 1,
//                 uint256(Raffle.RaffleState.CALCULATING)
//             )
//         );
//         raffle.performUpkeep(bytes(""));
//     }
// }

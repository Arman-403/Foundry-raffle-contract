//SPDX-License-Identifier :MIT

pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig, CodeConstants} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {Raffle} from "../../src/Raffle.sol";

contract RaffleTest is Test, CodeConstants {
    uint96 public constant INITIAL_PLAYER_BALANCE = 10 ether;
    address public PLAYER = makeAddr("player");

    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint32 callbackGasLimit;
    uint256 subscriptionId;

    /*//////////////////////////////////////////////////////////////
                           EVENTS FOR TESTING
    //////////////////////////////////////////////////////////////*/
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    function setUp() public {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        callbackGasLimit = config.callbackGasLimit;
        subscriptionId = config.subscriptionId;

        vm.deal(PLAYER, INITIAL_PLAYER_BALANCE);
    }

    function testRaffleStartWithOpen() public view {
        assert(uint256(raffle.getRaffleState()) == uint256(Raffle.RaffleState.OPEN));
    }

    /*//////////////////////////////////////////////////////////////
                              ENTER RAFFLE
    //////////////////////////////////////////////////////////////*/
    function testEnterRaffleRevertsWithoutEnoughEntranceFee() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    function testPlayerAddedToPlayersArray() public {
        vm.prank(PLAYER);

        raffle.enterRaffle{value: entranceFee}();
        address enteredPlayer = raffle.getPlayer(0);
        assertEq(raffle.getPlayer(0), enteredPlayer);
    }

    function testenterRaffleEmitsEvent() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testDontAllowPlayersWhileRaffleIsCalculating() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        // Act / Assert
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep(""); // changes the state to calculating

        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        raffle.enterRaffle{value: entranceFee}();
    }

    /*//////////////////////////////////////////////////////////////
                              CHECK UPKEEP
    //////////////////////////////////////////////////////////////*/

    function testCheckUpkeepReturnsFalseIfNoBalance() public {
        // Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        // Act
        (bool checkUpkeepNeeded,) = raffle.checkUpkeep("");
        // Assert
        assert(!checkUpkeepNeeded);
    }

    function testCheckUpkeepFalseIfRaffleNotOpen() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");
        // act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        // assert
        assertFalse(upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfNotEnoughTimePassed() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval - 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        assertFalse(upkeepNeeded);
    }

    function testCheckUpkeepReturnsTrueIfAllParametersGood() public {
        //  players and balance
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        //  enough time has passed
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        //  rafflestate
        assertEq(uint256(raffle.getRaffleState()), uint256(Raffle.RaffleState.OPEN));

        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        assertTrue(upkeepNeeded);
    }

    /*//////////////////////////////////////////////////////////////
                             PERFORM UPKEEP
    //////////////////////////////////////////////////////////////*/

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffleState rState = raffle.getRaffleState();

        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        currentBalance = currentBalance + entranceFee;
        numPlayers = numPlayers + 1;
        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, currentBalance, numPlayers, rState)
        );
        raffle.performUpkeep("");
    }

    modifier raffleEnteredAndTimePassed() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        _;
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public raffleEnteredAndTimePassed {
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        Raffle.RaffleState raffleState = raffle.getRaffleState();

        assert(uint256(requestId) > 0); //checks requestId is not empty
        assert(uint256(raffleState) == 1); // calculating
    }

    /*//////////////////////////////////////////////////////////////
                           FULFILLRANDOMWORDS
    //////////////////////////////////////////////////////////////*/

    modifier skipFork() {
        if (block.chainid != LOCAL_CHAIN_ID) {
            return;
        }
        _;
    }

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId)
        public
        raffleEnteredAndTimePassed
        skipFork
    {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));
    }

    function testFulfillRandomWordsPicksWinnerResetsAndSendMoney() public raffleEnteredAndTimePassed skipFork {
        // Arrange
        uint256 addtionalEntrants = 3; // total 4 because raffleEntered modifier has already entered with one
        uint256 startingIndex = 100;
        address expectedWinner = address(100);
        uint256 startTimeStamp = raffle.getLastTimeStamp();

        for (uint256 i = startingIndex; i < startingIndex + addtionalEntrants; i++) {
            address newPlayer = address(uint160(i));
            hoax(newPlayer, 1 ether);
            raffle.enterRaffle{value: entranceFee}();
        }
        uint256 startWinnerBalance = expectedWinner.balance;
        // Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

        // Assert
        uint256 prize = entranceFee * (addtionalEntrants + 1);
        uint256 endingTimeStamp = raffle.getLastTimeStamp();
        address recentWinner = raffle.getRecentWinner();
        uint256 winnerBalance = recentWinner.balance;
        Raffle.RaffleState raffleState = raffle.getRaffleState();

        assert(recentWinner == expectedWinner);
        assert(winnerBalance == startWinnerBalance + prize);
        assert(uint256(raffleState) == 0);
        assert(endingTimeStamp > startTimeStamp);
    }
}

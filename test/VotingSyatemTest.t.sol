// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {VotingSystem} from "../src/VotingSystem.sol";
import {DeployVotingSystem} from "../script/DeployVotingSystem.s.sol";

contract VotingSystemTest is Test {
    VotingSystem votingSystem;

    function setUp() public {
        // votingSystem = new VotingSystem();
        DeployVotingSystem deployVotingSystem = new DeployVotingSystem();
        votingSystem = deployVotingSystem.run();
    }

    // Candidate Registration

    function testCandidateRegistrationSuccess() public {
        string memory name = "John Doe";
        string memory party = "Liberty Party";
        uint256 age = 30;
        string memory gender = "Male";

        votingSystem.candidateRegister(name, party, age, gender);

        VotingSystem.Candidate[] memory candidates = votingSystem.candidateList();
        assertEq(candidates.length, 1, "Candidate registration failed");
        assertEq(candidates[0].name, name, "Candidate name mismatch");
        assertEq(candidates[0].party, party, "Candidate party mismatch");
        assertEq(candidates[0].age, age, "Candidate age mismatch");
        assertEq(candidates[0].gender, gender, "Candidate gender mismatch");
    }

    function testElectionCommissionTriesToRegisterCandidate() public {
        string memory name = "Jane Doe";
        string memory party = "Freedom Party";
        uint256 age = 35;
        string memory gender = "Female";

        (bool success, ) = address(votingSystem).call(
            abi.encodeWithSignature(
                "candidateRegister(string,string,uint256,string)",
                name,
                party,
                age,
                gender
            )
        );

        assertEq(success, false, "Election commission registered a candidate");
    }

    function testCandidateRegistrationTwice() public {
        string memory name = "Alice";
        string memory party = "Innovation Party";
        uint256 age = 25;
        string memory gender = "Female";

        votingSystem.candidateRegister(name, party, age, gender);

        (bool success, ) = address(votingSystem).call(
            abi.encodeWithSignature(
                "candidateRegister(string,string,uint256,string)",
                name,
                party,
                age,
                gender
            )
        );

        assertEq(success, false, "Candidate registered twice");
    }

    function testCandidateBelow18YearsOldTriesToRegister() public {
        string memory name = "Bob";
        string memory party = "Tech Party";
        uint256 age = 17;
        string memory gender = "Male";

        (bool success, ) = address(votingSystem).call(
            abi.encodeWithSignature(
                "candidateRegister(string,string,uint256,string)",
                name,
                party,
                age,
                gender
            )
        );

        assertEq(success, false, "Candidate below 18 registered");
    }

    function testCandidateRegistrationLimitReached() public {
        // Registering two candidates
        votingSystem.candidateRegister("Candidate1", "Party1", 30, "Male");
        votingSystem.candidateRegister("Candidate2", "Party2", 35, "Female");

        // Attempting to register a third candidate
        (bool success, ) = address(votingSystem).call(
            abi.encodeWithSignature(
                "candidateRegister(string,string,uint256,string)",
                "Candidate3",
                "Party3",
                25,
                "Male"
            )
        );

        assertEq(success, false, "Candidate registration limit not enforced");
    }

    // Voter Registration

    function testVoterRegistrationSuccess() public {
        string memory name = "Voter1";
        uint256 age = 25;
        string memory gender = "Female";

        votingSystem.voterRegister(name, age, gender);

        VotingSystem.Voter[] memory voters = votingSystem.voterList();
        assertEq(voters.length, 1, "Voter registration failed");
        assertEq(voters[0].name, name, "Voter name mismatch");
        assertEq(voters[0].age, age, "Voter age mismatch");
        assertEq(voters[0].gender, gender, "Voter gender mismatch");
    }

    function testRegisteredVoterTriesToRegisterAgain() public {
        string memory name = "Voter2";
        uint256 age = 30;
        string memory gender = "Male";

        votingSystem.voterRegister(name, age, gender);

        (bool success, ) = address(votingSystem).call(
            abi.encodeWithSignature("voterRegister(string,uint256,string)", name, age, gender)
        );

        assertEq(success, false, "Voter registered twice");
    }

    function testVoterBelow18YearsOldTriesToRegister() public {
        string memory name = "Voter3";
        uint256 age = 17;
        string memory gender = "Female";

        (bool success, ) = address(votingSystem).call(
            abi.encodeWithSignature("voterRegister(string,uint256,string)", name, age, gender)
        );

        assertEq(success, false, "Voter below 18 registered");
    }

    // Voting

    function testRegisteredVoterCastsVoteSuccessfully() public {
        // Register a candidate
        votingSystem.candidateRegister("Candidate1", "Party1", 30, "Male");

        // Register a voter
        votingSystem.voterRegister("Voter1", 25, "Female");

        // Cast vote
        votingSystem.vote(1, 1);

        // Check if vote was cast successfully
        VotingSystem.Voter[] memory voters = votingSystem.voterList();
        assertEq(voters[0].voteCandidateId, 1, "Vote not cast successfully");
    }

    function testVoterTriesToVoteTwice() public {
        // Register a candidate
        votingSystem.candidateRegister("Candidate1", "Party1", 30, "Male");

        // Register a voter
        votingSystem.voterRegister("Voter1", 25, "Female");

        // Cast vote once
        votingSystem.vote(1, 1);

        // Attempt to cast vote again
        (bool success, ) = address(votingSystem).call(abi.encodeWithSignature("vote(uint256,uint256)", 1, 1));

        assertEq(success, false, "Voter voted twice");
    }

    function testVoterVotesForInvalidCandidate() public {
        // Register a candidate
        votingSystem.candidateRegister("Candidate1", "Party1", 30, "Male");

        // Register a voter
        votingSystem.voterRegister("Voter1", 25, "Female");

        // Attempt to vote for an invalid candidate
        (bool success, ) = address(votingSystem).call(abi.encodeWithSignature("vote(uint256,uint256)", 1, 2));

        assertEq(success, false, "Voter voted for an invalid candidate");
    }

    function testVotingBeforeAllCandidatesRegister() public {
        // Register a candidate
        votingSystem.candidateRegister("Candidate1", "Party1", 30, "Male");

        // Register a voter
        votingSystem.voterRegister("Voter1", 25, "Female");

        // Attempt to vote before all candidates register
        (bool success, ) = address(votingSystem).call(abi.encodeWithSignature("vote(uint256,uint256)", 1, 1));

        assertEq(success, false, "Voting before all candidates register allowed");
    }

    // Result Declaration

    // function testElectionCommissionDeclaresResult() public {
    //     // Register candidates
    //     votingSystem.candidateRegister("Candidate1", "Party1", 30, "Male");
    //     votingSystem.candidateRegister("Candidate2", "Party2", 35, "Female");

    //     // Register voters and cast votes
    //     votingSystem.voterRegister("Voter1", 25, "Female");
    //     votingSystem.vote(1, 1);
    //     votingSystem.vote(2, 2);

    //     // Declare result
    //     votingSystem.result();

    //     assertEq(votingSystem.winner(), votingSystem.candidateAddress(), "Result declaration failed");
    // }

    function testNonElectionCommissionTriesToDeclareResult() public {
        // Attempt to declare result by non-election commission address
        (bool success, ) = address(votingSystem).call(abi.encodeWithSignature("result()"));

        assertEq(success, false, "Non-election commission declared result");
    }

    function testResultDeclarationWithoutAllCandidatesRegistered() public {
        // Register only one candidate
        votingSystem.candidateRegister("Candidate1", "Party1", 30, "Male");

        // Attempt to declare result without all candidates registered
        (bool success, ) = address(votingSystem).call(abi.encodeWithSignature("result()"));

        assertEq(success, false, "Result declared without all candidates registered");
    }
}





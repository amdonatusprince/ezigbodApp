// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract AssetTracker {
    
    struct Asset {
        string name;
        string description;
        uint cost;
        uint quantity;
        string manufacturer;
        string customer;
        string addressFrom;
        string addressTo;
        bool initialized;    
        bool arrived;
        uint distributorId;
    }

    struct Distributor {
        uint id;
        string name;
        string add;
        string email;
        string phone;
        bool exists;
    }

    mapping(uint => Distributor) private distributorStore;
    uint public distributorCount;

    mapping(uint => Asset) private assetStore;
    mapping(address => mapping(uint => bool)) private walletStore;
    uint public assetCount;

    event DistributorRejected(string name, string add, string email, string phone);
    event DistributorInserted(uint id, string name, string add, string email, string phone);
    event AssetCreated(string name, string description, uint cost, uint quantity, string manufacturer, string customer, string addressFrom, string addressTo, uint distributorId);
    event AssetTransferred(address from, address to, uint assetId);
    event AssetArrived(uint assetId);

    // Distributor methods

    function insertDistributor(string memory name, string memory add, string memory email, string memory phone) public returns (bool) {
        require(bytes(email).length > 0, "Email is required");

        // Check if the distributor already exists
        for (uint i = 0; i < distributorCount; i++) {
            if (keccak256(bytes(distributorStore[i].email)) == keccak256(bytes(email))) {
                emit DistributorRejected(name, add, email, phone);
                return false;
            }
        }

        // Insert the new distributor
        distributorStore[distributorCount] = Distributor(distributorCount, name, add, email, phone, true);
        distributorCount++;

        emit DistributorInserted(distributorCount - 1, name, add, email, phone);
        return true;
    }

    function getDistributorById(uint id) public view returns (uint, string memory, string memory, string memory, string memory) {
        require(distributorStore[id].exists, "Distributor does not exist");

        Distributor memory distributor = distributorStore[id];
        return (distributor.id, distributor.name, distributor.add, distributor.email, distributor.phone);
    }

    function getAllDistributors() public view returns (Distributor[] memory) {
        Distributor[] memory distributors = new Distributor[](distributorCount);

        for (uint i = 0; i < distributorCount; i++) {
            Distributor storage distributor = distributorStore[i];
            if (distributor.exists) {
                distributors[i] = distributor;
            }
        }

        return distributors;
    }

    // Asset methods

    function createAsset(
        string memory name,
        string memory description,
        uint distributorId,
        uint cost,
        uint quantity,
        string memory manufacturer,
        string memory customer,
        string memory addressFrom,
        string memory addressTo
    ) public {
        require(distributorStore[distributorId].exists, "Distributor does not exist");

        // Create the new asset
        assetStore[assetCount] = Asset(name, description, cost, quantity, manufacturer, customer, addressFrom, addressTo, true, false, distributorId);
        walletStore[msg.sender][assetCount] = true;
        assetCount++;

        emit AssetCreated(name, description, cost, quantity, manufacturer, customer, addressFrom, addressTo, distributorId);
    }

    function transferAsset(address to, uint assetId) public {
    require(assetStore[assetId].initialized, "Asset with the given ID does not exist");
    require(walletStore[msg.sender][assetId], "The sender does not own this asset");
    require(to != address(0), "Invalid address");

    walletStore[msg.sender][assetId] = false;
    walletStore[to][assetId] = true;

    emit AssetTransferred(msg.sender, to, assetId);
    }

    function getAssetDetails(uint assetId) public view returns (Asset memory) {
        require(assetId < assetCount, "Asset with the given ID does not exist");

        return assetStore[assetId];
    }

    function isAssetOwner(address owner, uint assetId) public view returns (bool) {
        return walletStore[owner][assetId];
    }

    function getAllAssets() public view returns (Asset[] memory) {
        Asset[] memory assets = new Asset[](assetCount);

        for (uint i = 0; i < assetCount; i++) {
            assets[i] = assetStore[i];
        }

        return assets;
    }

    function assetArrived(uint assetId) public { 
        require(assetStore[assetId].initialized, "Asset with the given ID does not exist");

        assetStore[assetId].arrived = true;

        emit AssetArrived(assetId);
    }



}
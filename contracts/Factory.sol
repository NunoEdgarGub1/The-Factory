pragma solidity ^0.4.11;


//Raw prototype of Profile factory


//TODO - DOCS


import './HubProfile.sol';
import './MinerProfile.sol';



contract Factory {

    token sharesTokenAddress;

    address dao;

    network Sonm;

    //Profile type
    enum TypeW {
     Hub,
     Miner,
     Client
   }

  TypeW public ProfileType;


    // owner => Profile
    mapping (address => address) public Profiles;

    //Profile types
    // Profile => type
    mapping (address => TypeW) public types;

    //Type of hubs.
    // Profile => type. true for private pools (clusters, datacentres, etc)
    mapping (address => bool) public privat;


    event LogCreate(address Profile, address owner);

    event LogCr(address owner);
    //  event Weird(string thing);

    function Factory(token TokenAddress, address _dao){
        sharesTokenAddress = TokenAddress;
        dao = _dao;
    }

    modifier onlyDao(){
        if (msg.sender != dao) revert();
        _;
    }

    function changeAdresses(address _dao, network _Sonm) public onlyDao {
        dao = _dao;
        Sonm = network(_Sonm);
    }



    function createHub(bool _privat) public returns (address) {
        address _hubowner = msg.sender;
        address hubProfile = createH(_hubowner,_privat);
        Profiles[_hubowner] = hubProfile;
        types[hubProfile] = TypeW.Hub;
        privat[hubProfile] = _privat;
        LogCreate(hubProfile, _hubowner);
    }

    function createMiner() public returns (address) {
        address _minowner = msg.sender;
        address minProfile = createM(_minowner);
        Profiles[_minowner] = minProfile;
        types[_minowner] = TypeW.Miner;
        LogCreate(minProfile, _minowner);
    }

    function createH(address _hubowner, bool _privat) private returns (address) {
        return address(new HubProfile(_hubowner, dao, Sonm, sharesTokenAddress,_privat));
        LogCr(_hubowner);
    }

    function createM(address _minowner) private returns (address) {
        return address(new MinerProfile(_minowner, dao, Sonm, sharesTokenAddress));
        LogCr(_minowner);
    }


    function getProfile(address _owner) constant returns (address _Profile) {
        return Profiles[_owner];
    }

    function getType(address _Profile) constant returns (TypeW _type) {
        return types[_Profile];
    }

    function isPrivate(address _Profile) constant returns (bool _private) {
        return privat[_Profile];
    }

}

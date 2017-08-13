pragma solidity ^0.4.4;

//Raw prototype for Miner Profile contract.





import "./zeppelin/ownership/Ownable.sol";

import "./Profile.sol";


contract MinerProfile is Ownable, Profile{

  ///@dev constructor
  function MinerProfile(address _minowner,address _dao,network _Network,token sharesAddress){
    owner=_minowner;
    DAO=_dao;
    Network= network(_Network);
    Factory=msg.sender;
    genesisTime=uint64(now);

    sharesTokenAddress = token(sharesAddress);

    //1 SNM token is needed to registrate in Network
    freezeQuote = 1 * (1 ether / 1 wei);



    //in promilles
    daoFee = 5;

    // time of work period.
    freezePeriod = 5 days;

  }

  event pulledMoney(address hub, uint amount);



  /*/
   *  Public functions
  /*/

  function Registration() public onlyOwner returns (bool success){
      if(currentPhase!=Phase.Idle) throw;
    if (sharesTokenAddress.balanceOf(this) <= freezeQuote) throw;
    frozenFunds=freezeQuote;

    //Appendix to call register function from Network contract and check it.
    if(!super.CheckIn()) throw;
    //Network.RegisterMin(owner,this,frozenTime);

    return true;
  }

  function pullMoney(address hubProfile) public onlyOwner{
    uint val = sharesTokenAddress.allowance(hubProfile,this);
    sharesTokenAddress.transferFrom(hubProfile,this,val);
    pulledMoney(hubProfile,val);
  }


  function PayDay() public onlyOwner {

    if(currentPhase!=Phase.Registred) throw;

    if(now < (frozenTime + freezePeriod)) throw;

    //dao got's 0.5% in such terms.
    uint DaoCollect = frozenFunds * daoFee / 1000;
  //  DaoCollect = DaoCollect + frozenFunds;
    frozenFunds = 0;


    sharesTokenAddress.transfer(DAO,DaoCollect);

    //Here need to do Unregister function
    if(!super.CheckOut()) throw;
    //Network.UnRegisterMiner(owner,this);

  }

}

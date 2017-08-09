pragma solidity ^0.4.8;

//sonm wallet abstraction



import "./zeppelin/ownership/Ownable.sol";
import "./Declaration.sol";



contract Wallet  is Ownable {



      /*/
       *  Constants
      /*/

      address public DAO;
      address public Factory;


      //address public Whitelist;
      whitelist Whitelist;


      token public sharesTokenAddress;


      //uint public freezePercent;

      // FreezeQuote - it is defined amount of tokens need to be frozen on  this contract.
      uint public freezeQuote;
      uint public frozenFunds;

      //lockedFunds - it is lockedFunds in percentage, which will be locked for every payday period.
      uint public lockPercent;
      uint public lockedFunds = 0;

      //TIMELOCK
      uint64 public frozenTime;
      uint public freezePeriod;
      uint64 public genesisTime;

      //Fee's
      uint daoFee;



      uint DaoCollect;


      modifier onlyDao()     { if(msg.sender != DAO) throw; _; }



      /*/
       *  Wallet state
      /*/

      enum Phase {
          Created,
          Registred,
          Idle,
          Suspected,
          Punished
      }


      Phase public currentPhase;


      /*/
       *  Events
      /*/


        event LogPhaseSwitch(Phase newPhase);




    /*/
     *  Public functions
    /*/






    //Register in whitelist
    function CheckIn() public returns (bool success){
        if(msg.sender!=address(this)) throw;
        // double check
        if(currentPhase!=Phase.Idle) throw;

      frozenTime=uint64(now);
      //Appendix to call register function from Whitelist contract and check it.
      Whitelist.Register(owner,this,frozenTime);

      currentPhase=Phase.Registred;
      LogPhaseSwitch(currentPhase);

      return true;
    }


    //DeRegister in whitelist
    function CheckOut() public returns (bool success){

        if(msg.sender!=address(this)) throw;
        //double check
        if(currentPhase!=Phase.Registred) throw;

        // Comment it for test.
      if(now < (frozenTime + freezePeriod)) throw;

      //Appendix to call register function from Whitelist contract and check it.
      Whitelist.DeRegister(owner,this);

      currentPhase=Phase.Idle;
      LogPhaseSwitch(currentPhase);

      return true;
    }






    function withdraw(address to) public onlyOwner {

      if(currentPhase!=Phase.Idle) throw;
      uint amount = sharesTokenAddress.balanceOf(this);
      sharesTokenAddress.transfer(to,amount);
    }



    function suspect() public  {
      if (currentPhase!=Phase.Registred) throw;
      frozenFunds = 0;
  //

      lockedFunds=sharesTokenAddress.balanceOf(this);
      frozenTime = uint64(now);
      currentPhase = Phase.Suspected;
      LogPhaseSwitch(currentPhase);
      freezePeriod = 120 days;
     CheckOut();
    }

    function gulag() public onlyDao {
      if (currentPhase!=Phase.Suspected) throw;
      if (now < (frozenTime + freezePeriod)) throw;
      uint amount = lockedFunds;
      sharesTokenAddress.transfer(DAO,amount);
      currentPhase = Phase.Punished;
      LogPhaseSwitch(currentPhase);

    }

    function rehub() public onlyDao {
      if (currentPhase!=Phase.Suspected) throw;
      lockedFunds = 0;
      frozenFunds = 0;

      currentPhase = Phase.Idle;
      LogPhaseSwitch(currentPhase);
    }


  }

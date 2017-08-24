pragma solidity ^0.4.11;

//sonm profile abstraction


import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
//import "./zeppelin/ownership/Ownable.sol";
//import "./Declaration.sol";
import "./Dealable.sol";



contract Profile  is Ownable, Dealable {



      /*/
       *  Constants
      /*/

      address public DAO;
      address public Factory;


      //address public Network;
      network Network;


      token public sharesTokenAddress;



      // FreezeQuote - it is defined amount of tokens need to be frozen on  this contract.
      uint public freezeQuote;


      //lockedFunds - it is lockedFunds in percentage, which will be locked for every payday period.
      //uint public lockPercent;
      uint public lockedFunds = 0;

      //TIMELOCK
      uint64 public frozenTime;
      uint public freezePeriod;
      uint64 public genesisTime;

      //Fee's
      uint daoFee;



      uint DaoCollect;

      uint public localRate = 0;
      uint public stake = 0;
      uint d_count = 0;



      modifier onlyDao()     { if(msg.sender != DAO) revert(); _; }



      /*/
       *  Profile state
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
        event LogDebug(string message);




    /*/
     *  Public functions
    /*/


    // Deals-------------------------------------------------------------------

    function OpenDeal(uint cost) public returns (bool success){

    //  if(currentPhase!=Phase.Registred) revert();
      require(currentPhase==Phase.Registred);
      uint c = d_count;
      address _buyer = msg.sender;
      require(super.start(c,cost,_buyer));
      d_count++;
      return true;
    }

    function CancelDeal(uint _lockId) public returns (bool success) {
      require(currentPhase==Phase.Registred);
      require(super.cancel(_lockId,msg.sender));
      return true;
    }

    function AbortDeal(uint _lockId) public returns (bool success) {
      require(currentPhase==Phase.Registred);
      require(super.abort(_lockId,msg.sender));
      return true;
    }

    function AcceptDeal(uint _lockId) public onlyOwner returns (bool success){
      require(currentPhase==Phase.Registred);
      require(super.accept(_lockId));
      return true;
    }

    function RejectDeal(uint _lockId) public onlyOwner returns (bool success) {
      require(currentPhase==Phase.Registred);
      require(super.reject(_lockId));
      return true;
    }


    // Should it be onlyOwner?
    // NOTICE - this and next functions are actually call functions, which returns data
    // from smart-contract, but does not change the state, therefore it is not consume gas
    function getOpened() public returns (bool success, uint id){
      require(currentPhase==Phase.Registred);
      uint _id;
      DealStatus s = DealStatus.None;
      uint i=0;

        do{
          s = getStatus(i);
          _id = i;
          i++;
        }
        while(s!=DealStatus.Open || i<=d_count);



      if (s!=DealStatus.Open) {
        return (false,_id);
      } else {
      return (true, _id);
      }
    }

    function getAccepted() public returns (bool success, uint id){
      uint _id;
      DealStatus s = DealStatus.None;
      uint i=0;

        do{
          s = getStatus(i);
          _id = i;
          i++;
        }
        while(s!=DealStatus.Accepted || i<=d_count);



      if (s!=DealStatus.Accepted) {
        return (false,_id);
      } else {
      return (true, _id);
      }
    }






    //-------------------------------------------------------------------------

    //Register in Network
    function CheckIn() internal returns (bool success){

        // double check
        require(currentPhase==Phase.Idle);

      frozenTime=uint64(now);
      //Appendix to call register function from Network contract and check it.
      Network.Register(owner,this,frozenTime);

      currentPhase=Phase.Registred;
      LogPhaseSwitch(currentPhase);
      return true;
    }


    //DeRegister in Network
    function CheckOut() internal returns (bool success){


        //double check
        require(currentPhase==Phase.Registred);

        // Comment it for test usage.
      if(now < (frozenTime + freezePeriod)) revert();

      //Appendix to call register function from Network contract and check it.
      Network.DeRegister(owner,this,localRate);

      currentPhase=Phase.Idle;
      LogPhaseSwitch(currentPhase);
      return true;
    }


    // RATINGS --------------------------------------------------------------

    function plusRate(uint amount) internal returns (bool success){

        localRate += amount;
        return true;
        }

    function minusRate(uint amount) internal returns (bool success){
        localRate -= amount;
        return true;
        }

    function getRate() public returns (uint localR){
      uint r=localRate;
      return r;
      }


    // Stake is a temprary value of tokens, which owner could hold on his accounts
    // Stake has influence to the total score
    function putStake(uint amount) public onlyOwner {
      require(currentPhase==Phase.Registred);
      uint lock = lockedFunds + amount;

      if(sharesTokenAddress.balanceOf(msg.sender)< (lock)) revert();

      uint l = stake + lock;
      uint s = stake + amount;
      stake = s;
      lockedFunds = l;
    }

    function takeStake() internal {
      // double chek of state here, may been improved
      require(currentPhase==Phase.Registred);
      uint l = lockedFunds;
      lockedFunds = l - stake;
      stake = 0;
    }


    function buyRate(uint amount) public onlyOwner {

      require(currentPhase==Phase.Registred);

      uint g = Network.getGlobalRate(owner,this);
      // Check this with intence in test stage
      uint p = g / 100;
      // Rates cannot be increased more than for 10% at one buy.
      p = p * 10;

      if (amount > p) revert();
      uint lock = lockedFunds + amount;

      if(sharesTokenAddress.balanceOf(msg.sender)< (lock)) revert();

      lockedFunds = lock;
      if(!plusRate(amount)) revert();

    }



//------TOKEN ITERACTION-------------------------------------------------------

    function transfer(address _to, uint _value) public onlyOwner {

      require(currentPhase==Phase.Registred);

          uint lockFee = _value * daoFee / 1000;
          uint lock = lockedFunds + lockFee;
          uint value=_value - lockFee;
          if(sharesTokenAddress.balanceOf(msg.sender)< (lock + value)) revert();
          lockedFunds=lock;
          sharesTokenAddress.transfer(_to,value);

    }


    function give(address _to, uint _value) public onlyOwner {


      require(currentPhase==Phase.Registred);

          uint lockFee = _value * daoFee / 1000;
          uint lock = lockedFunds + lockFee;
          uint value=_value - lockFee;

          if(sharesTokenAddress.balanceOf(msg.sender)< (lock + value)) revert();

          lockedFunds=lock;
          sharesTokenAddress.approve(_to,value);
    }

    function pullMoney(address Profile) public{
      require(currentPhase==Phase.Registred);
      uint val = sharesTokenAddress.allowance(Profile,this);
      sharesTokenAddress.transferFrom(Profile,this,val);

    }

//------------------------------------------------------------------------------
      function PayDay() public onlyOwner {

        require(currentPhase==Phase.Registred);

        takeStake();

        //uint balance = sharesTokenAddress.balanceOf(msg.sender);

        // !CONCEPTUAL
        // should we take a fee from turn?
        //  uint turn = balance * daoFee / 1000;
        DaoCollect = lockedFunds;
        //DaoCollect = DaoCollect + turn;
        lockedFunds= 0;

        // Comment it if you gonna run tests.
        if(now < (frozenTime + freezePeriod)) revert();



        //dao got's 0.5% in such terms.
          sharesTokenAddress.transfer(DAO,DaoCollect);
          if (!CheckOut()) revert();

      }

    function withdraw(address to, uint amount) public onlyOwner {

      require(currentPhase==Phase.Idle);
      sharesTokenAddress.transfer(to,amount);
    }



    function suspect() public onlyDao {
      require(currentPhase==Phase.Registred);

      frozenTime = uint64(now);
      currentPhase = Phase.Suspected;
      LogPhaseSwitch(currentPhase);
      freezePeriod = 120 days;
     CheckOut();
    }

    function punish() public onlyDao {
      require(currentPhase==Phase.Suspected);
      if (now < (frozenTime + freezePeriod)) revert();
      lockedFunds=sharesTokenAddress.balanceOf(this);
      uint amount = lockedFunds + stake;
      sharesTokenAddress.transfer(DAO,amount);
      currentPhase = Phase.Punished;
      LogPhaseSwitch(currentPhase);

    }

    function rehub() public onlyDao {
      require(currentPhase==Phase.Suspected);
      lockedFunds = 0;
      currentPhase = Phase.Idle;
      LogPhaseSwitch(currentPhase);
    }


  }

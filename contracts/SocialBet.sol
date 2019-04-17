pragma experimental ABIEncoderV2;

/// @title SocialBet
/// @notice
/// @dev
contract SocialBet {

	/// @notice Owner of SocialBet smart contract 
	address payable public owner;

	/// @notice Administrators mapping 
	mapping (address => bool) public admins;

	/// @notice Users balance mapping
	mapping (address => uint) public balances;
	/// @notice Events mapping
	mapping (uint => Event) public events;
	/// @notice Offers mapping
	mapping (uint => Offer) public offers;
	/// @notice Bets mapping
	mapping (uint => Bet) public bets;
	/// @notice Positions mapping
	mapping (uint => Position) public positions;

	/// @notice Number of events, used to set id of created events
	uint public m_nbEvents;
	/// @notice Number of offers, used to set id of created offers
	uint public m_nbOffers;
	/// @notice Number of bets, used to set id of created bets
	uint public m_nbBets;
	/// @notice Number of positions, used to set id of created positions
	uint public m_nbPositions;

	/// @notice Minimum ammount to maintain an Offer or a Position open to sell
	uint public m_minAmount = 10000000000000000;

	enum State { 
		OPEN, 
		CLOSE, 
		CANCELED 
	}

	enum Outcome { 
		NULL,
		CANCELED,  
		HOME, 
		AWAY, 
		DRAW, 
		OVER,
		UNDER,
		YES,
		NO
	}

	enum BetType { 
		HOMEAWAYDRAW, 
		MONEYLINE,
		OVERUNDER,
		POINTSPREAD,
		BOTHTEAMSCORE,
		FIRSTTEAMTOSCORE
	}

	enum OfferType { 
		BACK, 
		LAY 
	}


	event LogDeposit (address indexed account, uint amount);
	event LogWithdraw (address indexed account, uint amount);
	event LogBalanceChange (address indexed account, uint oldBalance, uint newBalance);
	event LogNewEvents (uint[] ids, bytes32[] ipfsAddress);
	event LogNewMarkets (uint[] ids);
	event LogResultEvents (uint[] ids);
	event LogCancelEvents (uint[] ids);
	event LogNewOffer (uint id, uint indexed eventId, uint indexed marketIndex, address indexed owner, uint amount, uint price, uint outcome, uint offerType);
	event LogUpdateOffer (uint indexed id, uint amount, uint price);
	event LogOfferClosed (uint id);
	event LogNewBet (uint id, uint indexed eventId, uint indexed marketIndex, uint backPosition, uint layPosition, uint amount, uint outcome);
	event LogBetClosed (uint id);
	event LogNewPosition (uint id, uint indexed betId, address indexed owner, uint amount, uint positionType);

	struct Event {
		uint 		_id;
		bytes32 	_ipfsAddress;
		uint 		_timestampStart;
		Market[]	_markets;
		State 		_state;
	}

	struct Market {
		BetType		_type;	
		bytes5 		_data;
		Outcome 	_outcome;
	}

	struct Offer {
		uint 		_id;
		uint 		_eventId;
		uint 		_marketIndex;
		address  	_owner;
		uint  		_amount;
		uint 		_price;
		Outcome 	_outcome;
		OfferType	_type;
	}

	struct Bet {
		uint  		_id;
		uint 		_eventId;
		uint 		_marketIndex;
		uint 		_backPosition;
		uint 		_layPosition;
		uint 		_amount;
		Outcome 	_outcome;
		State 		_state;
	}

	struct Position {
		uint 		_id;
		uint 		_betId;
		address 	_owner;
		uint 		_amount;
		OfferType	_type;
	}

	/// @dev Check that the caller is the Owner of the smart contract
	modifier isOwner () {
		require(owner == msg.sender);
		_;
	}

	/// @dev Check that the caller have admin rights
	modifier isAdmin () {
		require(admins[msg.sender]);
		_;
	}

	/// @dev Check that the event exists, is still open and has not started
	modifier eventAvailable (uint _eventId) {
		require (_eventId > 0);
		require (_eventId <= m_nbEvents);
		require (events[_eventId]._timestampStart > now);
		require (uint(events[_eventId]._state) == uint(State.OPEN));
		_;
	}

	/// @dev Check that the market exists
	modifier marketAvailable (uint _eventId, uint _marketIndex) {
		require (events[_eventId]._markets.length > _marketIndex);
		_;
	}

	/// @dev Check that the offer exists and is still open 
	modifier offerAvailable (uint _offerId) {
		require (_offerId > 0);
		require (_offerId <= m_nbOffers);
		require (events[offers[_offerId]._eventId]._timestampStart > now);
		require (uint(events[offers[_offerId]._eventId]._state) == uint(State.OPEN));
		require (offers[_offerId]._amount >= m_minAmount);
		require (offers[_offerId]._price >= m_minAmount);
		_;
	}

	/// @dev Check that the position exists and is still open 
	modifier positionAvailable (uint _positionId) {
		require (_positionId > 0);
		require (_positionId <= m_nbPositions);
		require (events[bets[positions[_positionId]._betId]._eventId]._timestampStart > now);
		require (uint(events[bets[positions[_positionId]._betId]._eventId]._state) == uint(State.OPEN));
		require (positions[_positionId]._amount >= m_minAmount);
		_;
	}

	/// @dev Check that the selected outcome is valid for the type of the selected event (DRAW is not possible for a HOMEAWAY event)
	modifier outcomeValid (uint _eventId, uint _marketIndex, uint _outcome) {
		if(events[_eventId]._markets[_marketIndex]._type == BetType.HOMEAWAYDRAW) {
			require (_outcome <= uint(Outcome.DRAW));
			require (_outcome >= uint(Outcome.HOME));
		}
		if(events[_eventId]._markets[_marketIndex]._type == BetType.MONEYLINE) {
			require (_outcome <= uint(Outcome.AWAY));
			require (_outcome >= uint(Outcome.HOME));
		}
		if(events[_eventId]._markets[_marketIndex]._type == BetType.OVERUNDER) {
			require (_outcome <= uint(Outcome.UNDER));
			require (_outcome >= uint(Outcome.OVER));
		}
		if(events[_eventId]._markets[_marketIndex]._type == BetType.POINTSPREAD) {
			require (_outcome <= uint(Outcome.AWAY));
			require (_outcome >= uint(Outcome.HOME));
		}
		if(events[_eventId]._markets[_marketIndex]._type == BetType.BOTHTEAMSCORE) {
			require (_outcome <= uint(Outcome.NO));
			require (_outcome >= uint(Outcome.YES));
		}
		if(events[_eventId]._markets[_marketIndex]._type == BetType.FIRSTTEAMTOSCORE) {
			require (_outcome <= uint(Outcome.AWAY));
			require (_outcome >= uint(Outcome.HOME));
		}
		_;
	}

	/// @dev Check that the odds of the offer are the same as it was when the user selected the offer
	modifier checkOddsOffer (uint _offerId, uint _odds) {
		require( div(mul(add(offers[_offerId]._amount, offers[_offerId]._price), 100), offers[_offerId]._price) == _odds, "Odds different from arguments");
		_;
	}


	/** 
	@notice Create SocialBet smart contract
	@dev The owner variable is set to the address of the caller of the constructor and the address is set as an admin
	*/
	constructor () public {
		owner = msg.sender;
		addAdmin(msg.sender);
	}

	/**
	@notice Add passed address as an admin
	@dev The value in the admins mapping is set to true at the passed address key
	@param _addr The address to set as an admin
	*/
	function addAdmin (address _addr) public isOwner {
		admins[_addr] = true;
	}

	/// @notice Remove passed address from admins
	/// @dev The value in the admins mapping is set to false at the passed address key
	/// @param _addr The address to unset from admins
	function removeAdmin (address _addr) external isOwner {
		require (_addr != owner);
		admins[_addr] = false;
	}

	/// @notice Bulk add new events to smart contract. The details of the event are found in the ipfs address passed 
	/// @param _ipfsAddressArr Array of the hash of the JSONs containing details of the saved events
	/// @param _timestampStartArr Array of the start timestamp of the saved events
	function addEventBulk (bytes32[] calldata _ipfsAddressArr, uint[] calldata _timestampStartArr, uint[][] calldata _marketsArr, bytes5[][] calldata _dataArr) external isAdmin {

		uint _length = _ipfsAddressArr.length;

		uint[] memory _ids = new uint[](_length);

		for(uint i=0; i<_length; i++) {
			_ids[i] = _addEvent(_ipfsAddressArr[i], _timestampStartArr[i], _marketsArr[i], _dataArr[i]);
		}

		emit LogNewEvents(_ids, _ipfsAddressArr);
	}

	function addMarkets (uint[] calldata _eventIdArr, uint[][] calldata _marketsArr, bytes5[][] calldata _dataArr) external isAdmin {

		for(uint i=0; i>_eventIdArr.length; i++) {
			for (uint j=0; j<_marketsArr[i].length; j++) {
				events[_eventIdArr[i]]._markets.push(Market(BetType(_marketsArr[i][j]), _dataArr[i][j], Outcome.NULL));
			}
		}
		
		emit LogNewMarkets(_eventIdArr);
	}

	/// @notice Bulk set events result 
	/// @param _eventIdArr Array of the id of the events to set result to
	/// @param _resultArr Array of the results to set
	function setEventResultBulk (uint[] calldata _eventIdArr, uint[][] calldata _resultArr) external isAdmin {

		for (uint i=0; i<_eventIdArr.length; i++) {
			_setEventResult(_eventIdArr[i], _resultArr[i]);
		}

		emit LogResultEvents(_eventIdArr);
	}

	/// @notice Bulk cancel of events
	/// @param _eventIdArr Array of the id of the events to cancel
	function cancelEventBulk (uint[] calldata _eventIdArr) external isAdmin {

		for (uint i=0; i<_eventIdArr.length; i++) {
			_cancelEvent(_eventIdArr[i]);
		}

		emit LogCancelEvents(_eventIdArr);
	}

	/// @notice Open a new offer on the selected event with the parameters passed as arguments
	/// @param _eventId Id of the event the offer is created on
	/// @param _amount Amount the bookmaker is putting on the offer
	/// @param _price Price the bookmaker is selling the offer for
	/// @param _outcome Outcome of the event the bookmaker is opening the offer on
	function openOffer (uint _eventId, uint _marketIndex, uint _amount, uint _price, uint _outcome, uint _type) external eventAvailable(_eventId) marketAvailable(_eventId, _marketIndex) outcomeValid(_eventId, _marketIndex, _outcome) {

		require (_price >= m_minAmount);
		require (_amount >= m_minAmount);
		require (_amount <= balances[msg.sender]);

		m_nbOffers = add(m_nbOffers, 1);

		Offer memory newOffer = Offer(m_nbOffers, _eventId, _marketIndex, msg.sender, _amount, _price, Outcome(_outcome), OfferType(_type));

		offers[newOffer._id] = newOffer;

		_subBalance(msg.sender, _amount);

		emit LogNewOffer(newOffer._id, newOffer._eventId, newOffer._marketIndex, newOffer._owner, newOffer._amount, newOffer._price, uint(newOffer._outcome), uint(newOffer._type));
	}

	/// @notice Update the price of an existing offer
	/// @param _offerId Id of the offer to update
	/// @param _price Price the bookmaker wants to update the offer to
	function updateOffer (uint _offerId, uint _price) external offerAvailable(_offerId) {

		require (offers[_offerId]._owner == msg.sender);
		require (_price >= m_minAmount);

		offers[_offerId]._price = _price;

		emit LogUpdateOffer(offers[_offerId]._id, offers[_offerId]._amount, offers[_offerId]._price);
	}

	/// @notice Close an existing offer
	/// @param _offerId Id of the offer to close
	function closeOffer (uint _offerId) external {

		require (_offerId > 0);
		require (_offerId <= m_nbOffers);
		require (offers[_offerId]._amount > 0);
		require (offers[_offerId]._owner == msg.sender);

		_closeOffer(_offerId);
	}

	/// @notice Fully or partly buy an offer and open a bet according to the parameters
	/// @param _offerId Id of the offer to buy
	/// @param _amount Amount the bettor wants to buy the offer with
	function buyOffer (uint _offerId, uint _amount, uint _odds) public offerAvailable(_offerId) checkOddsOffer(_offerId, _odds) {

		require (_amount >= m_minAmount);
		require (balances[msg.sender] >= _amount);
		require (offers[_offerId]._price >= _amount);

		Offer memory _offer = offers[_offerId];

		_subBalance(msg.sender, _amount);

		uint _amountOfferToBet = div(mul(_offer._amount, _amount), _offer._price);
		uint _restAmountOffer = sub(_offer._amount, _amountOfferToBet);
		uint _restPriceOffer = div(mul(_restAmountOffer, _offer._price), _offer._amount);

		m_nbBets = add(m_nbBets, 1);

		Bet memory _newBet;
		_newBet._id = m_nbBets;
		_newBet._eventId = _offer._eventId;
		_newBet._marketIndex = _offer._marketIndex;
		_newBet._outcome = _offer._outcome;
		_newBet._state = State.OPEN;

		Position memory backPosition;
		Position memory layPosition;

		if(_offer._type == OfferType.BACK) {
			backPosition = _createPosition(_newBet._id, _offer._owner, _amountOfferToBet, OfferType.BACK);
			layPosition = _createPosition(_newBet._id, msg.sender, _amount, OfferType.LAY);
		}
		if(_offer._type == OfferType.LAY) {
			backPosition = _createPosition(_newBet._id, msg.sender, _amount, OfferType.BACK);
			layPosition = _createPosition(_newBet._id, _offer._owner, _amountOfferToBet, OfferType.LAY);
		}

		_newBet._backPosition = backPosition._id;
		_newBet._layPosition = layPosition._id;
		_newBet._amount = backPosition._amount + layPosition._amount;

		bets[m_nbBets] = _newBet;

		emit LogNewBet(_newBet._id, _newBet._eventId, _newBet._marketIndex, _newBet._backPosition, _newBet._layPosition, _newBet._amount, uint(_newBet._outcome));

		offers[_offer._id]._amount = _restAmountOffer;
		offers[_offer._id]._price = _restPriceOffer;

		emit LogUpdateOffer(_offerId, _restAmountOffer, _restPriceOffer);

		if(_restAmountOffer < m_minAmount || _restPriceOffer < m_minAmount) {
			_closeOffer(_offer._id);
		}
	}

	/// @notice Fully or partly buy multiple offers and open bets according to the parameters
	/// @param _offerIdArr Array of the id of the offers to buy
	/// @param _amount Amount the bettor wants to buy the offers with
	function buyOfferBulk (uint[] calldata _offerIdArr, uint[] calldata _oddsArr, uint _amount) external {

		require (_amount >= m_minAmount);
		require (balances[msg.sender] >= _amount);

		uint _length = _offerIdArr.length;
		uint _restAmount = _amount;
		uint _offerAmount;
		uint _offerId;
		uint _odds;

		for (uint i=0; i<_length; i++) {

			if ( _restAmount < m_minAmount ) {
				break;
			}

			_offerId = _offerIdArr[i];
			_odds = _oddsArr[i];

			if( offers[_offerId]._price <= _restAmount ) {
				_offerAmount = offers[_offerId]._price;
			}
			else {
				_offerAmount = _restAmount;
			}

			buyOffer(_offerId, _offerAmount, _odds);
			
			_restAmount = sub(_restAmount, _offerAmount);
		}
	}

	/// @notice Claim bet earnings of a bet open on a close event
	function claimBetEarnings(uint _positionId) external {

		require (_positionId > 0);
		require (_positionId <= m_nbPositions);
		require (positions[_positionId]._owner == msg.sender);
		require (uint(bets[positions[_positionId]._betId]._state) == uint(State.OPEN));
		require (uint(events[bets[positions[_positionId]._betId]._eventId]._state) > uint(State.OPEN));

		Bet memory _bet = bets[positions[_positionId]._betId];
		Event memory _event = events[_bet._eventId];

		if(uint(_event._state) == uint(State.CANCELED)) {
			_addBalance(positions[_bet._backPosition]._owner, positions[_bet._backPosition]._amount);
			_addBalance(positions[_bet._layPosition]._owner, positions[_bet._layPosition]._amount);
		}
		else {
			if(_event._markets[_bet._marketIndex]._outcome == _bet._outcome && positions[_positionId]._type == OfferType.BACK) {
				_addBalance(positions[_positionId]._owner, _bet._amount);
			}
			else if (_event._markets[_bet._marketIndex]._outcome != _bet._outcome && positions[_positionId]._type == OfferType.LAY) {
				_addBalance(positions[_positionId]._owner, _bet._amount);
			}
		}

		_bet._state = State.CLOSE;
		bets[_bet._id] = _bet;

		emit LogBetClosed(_bet._id);
	}

	/// @notice Deposit 
	function deposit () payable external {

		require(msg.value > 0);

		_addBalance(msg.sender, msg.value);

		emit LogDeposit(msg.sender, msg.value);
	}

	/// @notice Withdraw
	/// @param _amount Amount to withdraw from user balance in smart contract to his account
	function withdraw (uint _amount) external {
		
		require(_amount > 0);

		_subBalance(msg.sender, _amount);

		msg.sender.transfer(_amount);

		emit LogWithdraw(msg.sender, _amount);
	}


	/// @notice Add the amount to the balance of the address passed in the arguments
	/// @param _addr Address of the balance to add the amount to
	/// @param _amount Amount to add to the balance
	function _addBalance (address _addr, uint _amount) private {

		uint _curBalance = balances[_addr];
		uint _newBalance = add(_curBalance, _amount);
		balances[_addr] = _newBalance;

		emit LogBalanceChange(_addr, _curBalance, _newBalance);
	} 

	/// @notice Subtract the amount to the balance of the address passed in the arguments
	/// @param _addr Address of the balance to subtract the amount from
	/// @param _amount Amount to subtract from the amount
	function _subBalance (address _addr, uint _amount) private {

		require (_amount <= balances[_addr]);

		uint _curBalance = balances[_addr];
		uint _newBalance = sub(_curBalance, _amount);
		balances[_addr] = _newBalance;

		emit LogBalanceChange(_addr, _curBalance, _newBalance);
	}

	/// @notice Add event 
	/// @param _ipfsAddress Hash of the JSON containing event details
	/// @param _timestampStart Start timestamp of the event
	function _addEvent(bytes32 _ipfsAddress, uint _timestampStart, uint[] memory _markets, bytes5[] memory _data) internal returns(uint _id){

		m_nbEvents = add(m_nbEvents, 1);

		Event memory newEvent = Event(m_nbEvents, _ipfsAddress, _timestampStart, new Market[](0), State.OPEN);

		events[newEvent._id] = newEvent;

		for (uint i=0; i<_markets.length; i++) {
			events[newEvent._id]._markets.push(Market(BetType(_markets[i]), _data[i], Outcome.NULL));
		}

		_id = m_nbEvents;
	}

	/// @notice Cancel event
	/// @param _eventId Id of the event
	function _cancelEvent(uint _eventId) private {

		Event memory _event = events[_eventId];

		_event._state = State.CANCELED;
		
		events[_event._id] = _event;
	}

	/// @notice Set result
	/// @param _eventId Id of the event
	/// @param _result Result of the event
	function _setEventResult (uint _eventId, uint[] memory _result) private {

		Event memory _event = events[_eventId];

		if( uint(_event._state) != uint(State.CLOSE) ) {

			for (uint i=0; i<_event._markets.length; i++) {
				_event._markets[i]._outcome = Outcome(_result[i]);
			}
			_event._state = State.CLOSE;
		}

		events[_event._id] = _event;
	}

	/// @notice Close an existing offer
	/// @param _offerId Id of the offer to close
	function _closeOffer (uint _offerId) private {

		Offer memory offer = offers[_offerId];

		_addBalance(offer._owner, offer._amount);

		offers[_offerId]._amount = 0;
		offers[_offerId]._price = 0;

		emit LogOfferClosed(_offerId);
	}

	/// @notice Create a new Position and adds it to the positions mapping
	/// @param _betId Id of the bet associated to the created position
	/// @param _owner Owner of the created position
	/// @param _amount Amount the owner have in the created position
	/// @param _type Role of the owner of the position in the associated bet
	function _createPosition (uint _betId, address _owner, uint _amount, OfferType _type) private returns (Position memory newPosition) {

		m_nbPositions = add(m_nbPositions, 1);

		newPosition = Position(m_nbPositions, _betId, _owner, _amount, _type);

		positions[newPosition._id] = newPosition;

		_logNewPosition(newPosition);
	}

	function _logNewPosition (Position memory newPosition) private {
		emit LogNewPosition(newPosition._id, newPosition._betId, newPosition._owner, newPosition._amount, uint(newPosition._type));
	}

	function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
		assert(_b <= _a);
		return _a - _b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}

	function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
		if (_a == 0) {
			return 0;
		}
		c = _a * _b;
		assert(c / _a == _b);
		return c;
	}

	function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
		return _a / _b;
	}

}

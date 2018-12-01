pragma solidity ^0.4.24;

contract SocialBet {


	/****************
	*** VARIABLES ***
	****************/

	address public owner;

	mapping (address => bool) public admins;
	
	mapping (address => uint) public balances;

	mapping (uint => Event) public events;
	mapping (uint => Offer) public offers;
	mapping (uint => Bet) public bets;
	mapping (uint => Position) public positions;
	
	uint public m_nbEvents;
	uint public m_nbOffers;
	uint public m_nbBets;
	uint public m_nbPositions;

	uint public m_feeBalance = 0;

	uint public m_tradeFee = 1;
	uint public m_publicFee = 2;
	uint public m_privateFee = 2;
	uint public m_minAmount = 10000000000000000;

	/*****************
	****** ENUM ******
	*****************/

	enum State { OPEN, CLOSE, CANCELED }

	enum Pick { NULL, HOME, AWAY, DRAW, CANCELED }

	enum Type { HOMEAWAYDRAW, HOMEAWAY }

	enum Role { BOOKMAKER, BETTOR }

	/*****************
	***** EVENTS *****
	*****************/

	event LogDeposit(address indexed account, uint amount);
	event LogWithdraw(address indexed account, uint amount);
	event LogBalanceChange(address indexed account, uint oldBalance, uint newBalance);
	event LogNewEvents(uint[] id, bytes32[] ipfsAddress);
	event LogResultsEvent(uint[] id, uint[] result);
	event LogCancelEvent(uint[] id);
	event LogNewOffer(uint id, uint indexed eventId, address indexed owner, uint amount, uint price, uint pick);
	event LogUpdateOffer(uint indexed id, address indexed owner, uint amount, uint price);
	event LogOfferClosed(uint id, address indexed owner);
	event LogNewBet(uint id, uint indexed eventId, uint[] positions, uint pick);
	event LogBetClosed(uint id);
	event LogNewPosition(uint id, uint indexed betId, address indexed owner, uint amount, uint amountToEarn, uint price, uint role);
	event LogUpdatePosition(uint id, address indexed owner, uint amount, uint amountToEarn, uint price);
	
	/*****************
	***** STRUCT *****
	*****************/

	struct Event {
		uint 		_id;
		bytes32 	_ipfsAddress;  
		uint 		_timestampStart;
		Type		_type;
		Pick 		_result;
		State 		_state;
		uint 		_resultAttempts;
	}

	struct Offer {
		uint 		_id;
		uint 		_eventId;
		address  	_owner;
		uint  		_amount;
		uint 		_price;
		Pick 		_pick;
		State		_state;
	}
	
	struct Bet {
		uint  		_id;
		uint 		_eventId;
		uint[] 		_positions;
		Pick 		_pick;
		State 		_state;
	}

	struct Position {
		uint 		_id;
		uint 		_betId;
		address 	_owner;
		uint 		_amount;
		uint 		_amountToEarn;
		uint 		_price;
		Role		_role;
	}
	

	/****************
	*** MODIFIERS ***
	****************/

	modifier isOwner() { 
		require(owner == msg.sender); 
		_; 
	}

	modifier isAdmin() { 
		require(admins[msg.sender]);
		_; 
	}
	

	/****************
	** CONSTRUCTOR **
	****************/
	
	constructor () public {
		owner = msg.sender;
		addAdmin(msg.sender);
	}

	/**********************
	*** ADMIN FUNCTIONS ***
	**********************/

	function addAdmin(address _addr) public isOwner {
		admins[_addr] = true;
	}

	function removeAdmin(address _addr) external isOwner {
		admins[_addr] = false;
	}

	function claimFees() external isOwner {

		uint _amount = m_feeBalance;
		m_feeBalance = 0;

		owner.transfer(_amount);
	}

	function addEvents(uint[] _typeArr, bytes32[] _ipfsAddressArr, uint[] _timestampStartArr) external isAdmin {

		require(_typeArr.length == _ipfsAddressArr.length);
		require(_typeArr.length == _timestampStartArr.length);

		uint _length = _typeArr.length;

		uint[] memory _ids = new uint[](_length);

		for(uint i=0; i<_length; i++) {
			// Checks
			if(_timestampStartArr[i] > now) {
				if(_typeArr[i] <= uint(Type.HOMEAWAY)) {
					// Increment number of Events
					m_nbEvents = add(m_nbEvents, 1);

					// Create new Event
					Event memory newEvent = Event(m_nbEvents, _ipfsAddressArr[i], _timestampStartArr[i], Type(_typeArr[i]), Pick.NULL, State.OPEN, 0);

					// Add Event inside mapping 
					events[newEvent._id] = newEvent;

					_ids[i] = m_nbEvents;
				}
				else {
					_ids[i] = 0;
				}
			}
			else {
				_ids[i] = 0;
			}
		}

		emit LogNewEvents(_ids, _ipfsAddressArr);
	}

	function setEventResult(uint[] _eventIdArr, uint[] _resultArr) external isAdmin {		

		require(_eventIdArr.length == _resultArr.length);

		uint _length = _eventIdArr.length;

		uint[] memory _results = new uint[](_length);

		for (uint i=0; i<_length; i++) {

			Event memory _event = events[_eventIdArr[i]];

			_event = setResult(_event, _resultArr[i]);

			events[_event._id] = _event;

			_results[i] = uint(_event._result);
		}

		emit LogResultsEvent(_eventIdArr, _results);
	}

	function cancelEvent(uint[] _eventIdArr) external isAdmin {

		uint _length = _eventIdArr.length;

		uint[] memory _arr = new uint[](_length);

		for (uint i=0; i<_length; i++) {

			require(_eventIdArr[i] <= m_nbEvents);
			require(_eventIdArr[i] > 0);
			require(uint(events[_eventIdArr[i]]._state) == uint(State.OPEN));

			Event memory _event = events[_eventIdArr[i]];

			_event._state = State.CANCELED;

			events[_event._id] = _event;

			_arr[i] = _event._id;

		}

		emit LogCancelEvent(_arr);

	}


	/**********************
	*** USERS FUNCTIONS ***
	**********************/



	function openOffer (uint _eventId, uint _amount, uint _price, uint _pick) public {

		// Checks
		require (_amount >= m_minAmount);
		require (_amount <= balances[msg.sender]);
		require (_price >= m_minAmount);
		require (_eventId > 0);
		require (_eventId <= m_nbEvents);
		if(events[_eventId]._type == Type.HOMEAWAY) {
			require (_pick <= uint(Pick.AWAY));
		}
		else {
			require (_pick <= uint(Pick.DRAW));
		}
		require (_pick >= uint(Pick.HOME));
		require (events[_eventId]._timestampStart > now);
		require (uint(events[_eventId]._state) == uint(State.OPEN));

		// Increment number of Offers
		m_nbOffers = add(m_nbOffers, 1);

		// Create new Offer
		Offer memory newOffer = Offer(m_nbOffers, _eventId, msg.sender, _amount, _price, Pick(_pick), State.OPEN);

		// Update user balance
		uint _curBalance = balances[msg.sender];
		uint _newBalance = sub(_curBalance, _amount);
		balances[msg.sender] = _newBalance;

		// Add Offer inside mapping
		offers[newOffer._id] = newOffer;

		emit LogBalanceChange(msg.sender, _curBalance, _newBalance);
		emit LogNewOffer(newOffer._id, newOffer._eventId, newOffer._owner, newOffer._amount, newOffer._price, uint(newOffer._pick));
	}

	function updateOffer (uint _offerId, uint _price) public {
		
		require(_offerId <= m_nbOffers);
		require (offers[_offerId]._id > 0);
		require (offers[_offerId]._owner == msg.sender);
		require (offers[_offerId]._state == State.OPEN);
		require (_price >= m_minAmount);
		
		offers[_offerId]._price = _price;

		emit LogUpdateOffer(offers[_offerId]._id, offers[_offerId]._owner, offers[_offerId]._amount, offers[_offerId]._price);
	}

	function askCloseOffer (uint _offerId) public {

		require(_offerId <= m_nbOffers);
		require (offers[_offerId]._id > 0);
		require (offers[_offerId]._owner == msg.sender);
		require (offers[_offerId]._state == State.OPEN);

		closeOffer(_offerId);
	}

	function buyOffer (uint _offerId, uint _amount) public {

		require (_offerId <= m_nbOffers);
		require (offers[_offerId]._id > 0);
		require (offers[_offerId]._state == State.OPEN);
		require (offers[_offerId]._amount >= m_minAmount);
		require (offers[_offerId]._price >= _amount);
		require (_amount >= m_minAmount);
		require (balances[msg.sender] >= _amount);

		Offer memory offer = offers[_offerId];

		require (uint(events[offer._eventId]._state) == uint(State.OPEN));

		// Calculate offer amount to go in bet and rests
		uint _amountBookmaker = div(mul(offer._amount, _amount), offer._price);
		uint _restAmountOffer = sub(offer._amount, _amountBookmaker);
		uint _restPriceOffer = div(mul(_restAmountOffer, offer._price), offer._amount);
		uint _amountToEarn = add(_amountBookmaker, _amount);

		// Increment number of Bets
		m_nbBets = add(m_nbBets, 1);

		// Create new Bet
		Bet memory newBet = Bet(m_nbBets, offer._eventId, new uint[](0), offer._pick, State.OPEN);

		// Add Bet inside mapping
		bets[newBet._id] = newBet;

		// Create positions linked to the bet
		Position memory p1 = createPosition(newBet._id, offer._owner, _amountBookmaker, _amountToEarn, Role.BOOKMAKER);
		Position memory p2 = createPosition(newBet._id, msg.sender, _amount,  _amountToEarn, Role.BETTOR);

		// Add positions to bet
		bets[newBet._id]._positions.push(p1._id);
		bets[newBet._id]._positions.push(p2._id);

		// Update user balance
		uint _curBalance = balances[msg.sender];
		uint _newBalance = sub(_curBalance, _amount);
		balances[msg.sender] = _newBalance;

		emit LogBalanceChange(msg.sender, _curBalance, _newBalance);

		// Update offer balance
		offers[offer._id]._amount = _restAmountOffer;
		offers[offer._id]._price = _restPriceOffer;

		emit LogUpdateOffer(_offerId, offer._owner, _restAmountOffer, _restPriceOffer);
		
		if(_restAmountOffer < m_minAmount || _restPriceOffer < m_minAmount) {
			closeOffer(offer._id);
		}

		emit LogNewBet(newBet._id, newBet._eventId, bets[newBet._id]._positions, uint(newBet._pick));
	}

	function buyOfferBatch (uint[] _offerIds, uint _amount) public {

		require (_amount >= m_minAmount);
		require (balances[msg.sender] >= _amount);

		uint _length = _offerIds.length;
		uint _restAmount = _amount;
		uint _offerAmount;

		for (uint i=0; i<_length; i++) {

			if ( _restAmount < m_minAmount ) {
				break;
			}

			uint _offerId = _offerIds[i];

			require (offers[_offerId]._id > 0);
			require (offers[_offerId]._state == State.OPEN);
			require (offers[_offerId]._amount >= m_minAmount);

			if( offers[_offerId]._price <= _restAmount ) {
				_offerAmount = offers[_offerId]._price;
			}
			else {
				_offerAmount = _restAmount;
			}

			buyOffer(_offerId, _offerAmount);

			_restAmount = sub(_restAmount, _offerAmount);
		}
	}

	function updatePosition(uint _positionId, uint _price) public {

		require (_positionId <= m_nbPositions);
		require (_price > m_minAmount);

		Position memory _position = positions[_positionId];
		Bet memory _bet = bets[_position._betId];
		Event memory _event = events[_bet._eventId];

		require (_event._timestampStart < now);
		require (uint(_event._state) == uint(State.OPEN));
		require (_position._owner == msg.sender);
		require (_position._amount > m_minAmount);
		
		_position._price = _price;

		positions[_position._id] = _position;
		
		emit LogUpdatePosition(_position._id, _position._owner, _position._amount, _position._amountToEarn, _position._price);
	}

	function buyPosition(uint _positionId, uint _amount) public {

		require (balances[msg.sender] >= _amount);
		require (_positionId <= m_nbPositions);
		require (_amount > m_minAmount);

		Position memory _position = positions[_positionId];
		Bet memory _bet = bets[_position._betId];
		Event memory _event = events[_bet._eventId];

		require (_position._price > m_minAmount);
		require (_event._timestampStart < now);
		require (uint(_event._state) == uint(State.OPEN));
		require (_position._owner == msg.sender);
		require (_position._amount > m_minAmount);
		
		uint _newPositionAmount =  div(mul(_position._amount, _amount), _position._price);
		uint _newPositionAmountToEarn = div(mul(_position._amountToEarn, _amount), _position._price);

		_position._amount = sub(_position._amount, _newPositionAmount);
		_position._amountToEarn = sub(_position._amountToEarn, _newPositionAmountToEarn);
		_position._price = sub(_position._price, _amount);

		Position memory p = createPosition(_position._betId, msg.sender, _newPositionAmount, _newPositionAmountToEarn, _position._role);

		positions[_position._id] = _position;

		bets[_bet._id]._positions.push(p._id);

		uint _curBalanceBuyer = balances[msg.sender];
		uint _newBalanceBuyer = sub(_curBalanceBuyer, _amount);
		balances[msg.sender] = _newBalanceBuyer;

		uint _fees = div(mul(_amount, m_tradeFee), 100);

		m_feeBalance = add(m_feeBalance, _fees);

		uint _curBalanceSeller = balances[_position._owner];
		uint _newBalanceSeller = add(_curBalanceSeller, sub(_amount, _fees));
		balances[msg.sender] = _newBalanceSeller;

		emit LogBalanceChange(msg.sender, _curBalanceBuyer, _newBalanceBuyer);
		emit LogBalanceChange(_position._owner, _curBalanceSeller, _newBalanceSeller);
		emit LogUpdatePosition(_position._id, _position._owner, _position._amount, _position._amountToEarn, _position._price);

	}

	function claimBetEarnings(uint _betId) public {

		require (_betId <= m_nbBets);
		
		Bet memory _bet = bets[_betId];
		Event memory _event = events[_bet._eventId];

		require(uint(_event._state) == uint(State.CLOSE));
		require(uint(_event._result) > uint(Pick.NULL));
		require(uint(_bet._state) == uint(State.OPEN));

		uint _length = _bet._positions.length;
		uint i;
		Position memory _position;

		if(uint(_event._result) <= uint(Pick.DRAW)) {

			for (i=0; i<_length; i++) {

				_position = positions[_bet._positions[i]];

				if( (_bet._pick == _event._result && _position._role == Role.BETTOR ) || ( _bet._pick != _event._result && _position._role == Role.BOOKMAKER ) ) {

					uint _fees = div(mul(_position._amountToEarn, m_publicFee), 100);
					uint _earnings = sub(_position._amountToEarn, _fees);

					m_feeBalance = add(m_feeBalance, _fees);

					uint _winnerPrevBalance = balances[_position._owner];
					uint _winnerNewBalance = add(_winnerPrevBalance, _earnings);
					balances[_position._owner] = _winnerNewBalance;

					emit LogBalanceChange(_position._owner, _winnerPrevBalance, _winnerNewBalance);
				}

			}
		}
		
		if(uint(_event._result) == uint(Pick.CANCELED)) {

			for (i=0; i<_length; i++) {

				_position = positions[_bet._positions[i]];

				uint _prevBalance = balances[_position._owner];
				uint _newBalance = add(_prevBalance, _position._amount);
				balances[_position._owner] = _newBalance;

				emit LogBalanceChange(_position._owner, _prevBalance, _newBalance);
			}
		}

		_bet._state = State.CLOSE;
		bets[_bet._id] = _bet;

		emit LogBetClosed(_bet._id);
	}	

	function deposit () payable public {
		require (msg.value > 0);

		uint _curBalance = balances[msg.sender];
		uint _newBalance = add(_curBalance, msg.value);
		balances[msg.sender] = _newBalance;

		emit LogDeposit(msg.sender, msg.value);
		emit LogBalanceChange(msg.sender, _curBalance, _newBalance);
	}

	function withdraw (uint _amount) public {
		require (_amount > 0);

		uint _curBalance = balances[msg.sender];
		uint _newBalance = sub(_curBalance, _amount);

		balances[msg.sender] = _newBalance;

		msg.sender.transfer(_amount);

		emit LogWithdraw(msg.sender, _amount);
		emit LogBalanceChange(msg.sender, _curBalance, _newBalance);
	}

	/*************************
	*** INTERNAL FUNCTIONS ***
	*************************/

	function closeOffer (uint _offerId) internal {

		Offer memory offer = offers[_offerId];

		uint _curBalance = balances[offer._owner];
		uint _newBalance = add(_curBalance, offer._amount);
		balances[offer._owner] = _newBalance;

		offers[_offerId]._amount = 0;
		offers[_offerId]._price = 0;

		offers[_offerId]._state = State.CLOSE;

		emit LogBalanceChange(offer._owner, _curBalance, _newBalance);
		emit LogOfferClosed(_offerId, offer._owner);
	}

	function createPosition (uint _betId, address _owner, uint _amount, uint _amountToEarn, Role _role) internal returns (Position newPosition) {

		// Increment number of Positions
		m_nbPositions = add(m_nbPositions, 1);

		// Create new position
		newPosition = Position(m_nbPositions, _betId, _owner, _amount, _amountToEarn, 0, _role);

		// Add positions inside mapping
		positions[newPosition._id] = newPosition;

		emit LogNewPosition(newPosition._id, newPosition._betId, newPosition._owner, newPosition._amount, newPosition._amountToEarn, newPosition._price, uint(newPosition._role));
	}

	function setResult (Event _event, uint _result) internal returns (Event) {

		if( ( uint(_event._result) == uint(Pick.NULL) ) && ( uint(_event._state) != uint(State.CLOSE) ) ) {

			_event._resultAttempts = add(_event._resultAttempts, 1);

			if( _result > uint(Pick.NULL) ) {

				if( _result == uint(Pick.CANCELED) ) {
					_event._result = Pick(_result);
					_event._state = State.CLOSE;
				}

				else if( ( uint(_event._type) == uint(Type.HOMEAWAY) && _result <= uint(Pick.AWAY) ) || ( uint(_event._type) == uint(Type.HOMEAWAYDRAW) && _result <= uint(Pick.DRAW) ) ) {
					_event._result = Pick(_result);
					_event._state = State.CLOSE;
				}
			}
			else {
				if( _event._resultAttempts >= 3 ) {
					_event._result = Pick.CANCELED;
					_event._state = State.CLOSE;
				}
			}
		}

		return _event;
	}

	/*************************
	***** UTILS FUNCTIONS ****
	*************************/

	function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
		assert(_b <= _a);
		return _a - _b;
	}

	function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
		c = _a + _b;
		assert(c >= _a);
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
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
	uint public m_publicFee = 1;
	uint public m_privateFee = 1;
	uint public m_minAmount = 10000000000000000;

	/*****************
	****** ENUM ******
	*****************/

	enum State { OPEN, CLOSE }

	enum Pick { NULL, HOME, AWAY, DRAW }

	enum Type { HOMEAWAYDRAW, HOMEAWAY }

	enum Role { BOOKMAKER, BETTOR }

	/*****************
	***** EVENTS *****
	*****************/

	// event LogDeposit(address indexed account);
	// event LogWithdraw(address indexed account);
	event LogDeposit(address indexed account, uint amount);
	event LogWithdraw(address indexed account, uint amount);
	event LogBalanceChange(address indexed account, uint oldBalance, uint newBalance);
	event LogNewEvents(uint[] id, bytes32[] ipfsAddress);
	event LogResultsEvent(uint[] id, uint[] result);
	event LogNewOffer(uint id, uint indexed eventId, address indexed owner, uint amount, uint price, uint pick);
	event LogUpdateOffer(uint indexed id, address indexed owner, uint amount, uint price);
	// event LogOfferClosed(uint indexed id, address indexed owner);
	event LogOfferClosed(uint id, address indexed owner);
	event LogNewBet(uint id, uint indexed eventId, uint[] positions, uint pick);
	event LogBetClosed(uint id);
	event LogNewPosition(uint id, uint indexed betId, address indexed owner, uint amount, uint amountToEarn, uint price, uint role);
	
	/*****************
	***** STRUCT *****
	*****************/

	struct Event {
		uint 		_id;
		bytes32 	_ipfsAddress;  
		uint 		_timestampStart;
		Type		_type;
		Pick 		_result;
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
					Event memory newEvent = Event(m_nbEvents, _ipfsAddressArr[i], _timestampStartArr[i], Type(_typeArr[i]), Pick.NULL);

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

			if(uint(_event._result) == uint(Pick.NULL)) {

				if( _resultArr[i] > uint(Pick.NULL) ) {

					if( ( uint(_event._type) == uint(Type.HOMEAWAY) && _resultArr[i] <= uint(Pick.AWAY) ) || ( uint(_event._type) == uint(Type.HOMEAWAYDRAW) && _resultArr[i] <= uint(Pick.DRAW) ) ) {

						_event._result = Pick(_resultArr[i]);

						events[_event._id] = _event;

						_results[i] = _resultArr[i];
					}
					else {
						_results[i] = 0;
					}

				}
				else {
					_results[i] = 0;
				}
			}
			else {
				_results[i] = uint(_event._result);
			}
		}

		emit LogResultsEvent(_eventIdArr, _results);
	}


	/**********************
	*** USERS FUNCTIONS ***
	**********************/



	function openOffer (uint _eventId, uint _amount, uint _price, uint _pick) public {

		// Checks
		require (_amount > m_minAmount);
		require (_amount <= balances[msg.sender]);
		require (_price > m_minAmount);
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

	function askCloseOffer (uint _offerId) public {

		require (offers[_offerId]._id > 0);
		require (offers[_offerId]._owner == msg.sender);
		require (offers[_offerId]._state == State.OPEN);

		closeOffer(_offerId);
	}

	function buyOffer (uint _offerId, uint _amount) public {

		require (offers[_offerId]._id > 0);
		require (offers[_offerId]._state == State.OPEN);
		require (offers[_offerId]._amount >= m_minAmount);
		require (offers[_offerId]._price >= _amount);
		require (_amount >= m_minAmount);
		require (balances[msg.sender] >= _amount);

		// Get offer
		Offer memory offer = offers[_offerId];

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

	function claimBetEarnings(uint _betId) public {
		
		Bet memory _bet = bets[_betId];
		Event memory _event = events[_bet._eventId];

		require(uint(_bet._state) == uint(State.OPEN));
		require(uint(_event._result) > uint(Pick.NULL));

		uint _length = _bet._positions.length;

		for (uint i=0; i<_length; i++) {

			Position memory _position = positions[_bet._positions[i]];

			if( (_bet._pick == _event._result && _position._role == Role.BETTOR ) || ( _bet._pick != _event._result && _position._role == Role.BOOKMAKER ) ) {

				uint _fees = div(mul(_position._amountToEarn, m_publicFee), 100);
				uint _earnings = sub(_position._amountToEarn, _fees);

				m_feeBalance = add(m_feeBalance, _fees);

				uint _winnerPrevBalance = balances[_position._owner];
				uint _winnerNewBalance = add(_winnerPrevBalance, _earnings);
				balances[_position._owner] = _winnerNewBalance;

				emit LogBalanceChange(_position._owner, _winnerPrevBalance, _winnerNewBalance);
			}

			// _position._amountToEarn = 0;

			// positions[_position._id] = _position;

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
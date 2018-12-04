pragma solidity ^0.5.1;

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

	/// @notice Fees balance
	uint public m_feeBalance = 0;

	/// @notice Fees applied to trade action
	uint public m_tradeFee = 1;
	/// @notice Fees applied to claim action
	uint public m_publicFee = 2;
	/// @notice Minimum ammount to maintain an Offer or a Position open to sell
	uint public m_minAmount = 10000000000000000;


	enum State { OPEN, CLOSE, CANCELED }

	enum Pick { NULL, HOME, AWAY, DRAW, CANCELED }

	enum Type { HOMEAWAYDRAW, HOMEAWAY }

	enum Role { BOOKMAKER, BETTOR }


	event LogDeposit (address indexed account, uint amount);
	event LogWithdraw (address indexed account, uint amount);
	event LogBalanceChange (address indexed account, uint oldBalance, uint newBalance);
	event LogNewEvents (uint[] id, bytes32[] ipfsAddress);
	event LogResultsEvent (uint[] id, uint[] result);
	event LogCancelEvent (uint[] id);
	event LogNewOffer (uint id, uint indexed eventId, address indexed owner, uint amount, uint price, uint pick);
	event LogUpdateOffer (uint indexed id, address indexed owner, uint amount, uint price);
	event LogOfferClosed (uint id, address indexed owner);
	event LogNewBet (uint id, uint indexed eventId, uint[] positions, uint pick);
	event LogBetClosed (uint id);
	event LogNewPosition (uint id, uint indexed betId, address indexed owner, uint amount, uint amountToEarn, uint price, uint role);
	event LogUpdatePosition (uint id, address indexed owner, uint amount, uint amountToEarn, uint price);


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

	/// @dev Check that the offer exists and is still open 
	modifier offerAvailable (uint _offerId) {
		require (_offerId <= m_nbOffers);
		require (offers[_offerId]._id > 0);
		require (offers[_offerId]._state == State.OPEN);
		_;
	}

	/// @dev Check that the selected pick is valid for the type of the selected event (DRAW is not possible for a HOMEAWAY event)
	modifier pickValid (uint _eventId, uint _pick) {
		if(events[_eventId]._type == Type.HOMEAWAY) {
			require (_pick <= uint(Pick.AWAY));
		}
		else {
			require (_pick <= uint(Pick.DRAW));
		}
		require (_pick >= uint(Pick.HOME));
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

	/// @notice Send the amount of fees collected to the owner address 
	function claimFees () external isOwner {
		uint _amount = m_feeBalance;
		m_feeBalance = 0;
		owner.transfer(_amount);
	}

	/// @notice Bulk add new events to smart contract. The details of the event are found in the ipfs address passed 
	/// @param _typeArr Array of the types of the saved events
	/// @param _ipfsAddressArr Array of the hash of the JSONs containing details of the saved events
	/// @param _timestampStartArr Array of the start timestamp of the saved events
	function addEventBulk (uint[] calldata _typeArr, bytes32[] calldata _ipfsAddressArr, uint[] calldata _timestampStartArr) external isAdmin {

		require(_typeArr.length == _ipfsAddressArr.length);
		require(_typeArr.length == _timestampStartArr.length);

		uint _length = _typeArr.length;

		uint[] memory _ids = new uint[](_length);

		for(uint i=0; i<_length; i++) {
			_ids[i] = _addEvent(_typeArr[i], _ipfsAddressArr[i], _timestampStartArr[i]);
		}

		emit LogNewEvents(_ids, _ipfsAddressArr);
	}

	/// @notice Bulk set events result 
	/// @param _eventIdArr Array of the id of the events to set result to
	/// @param _resultArr Array of the results to set
	function setEventResultBulk (uint[] calldata _eventIdArr, uint[] calldata _resultArr) external isAdmin {

		require(_eventIdArr.length == _resultArr.length);

		uint _length = _eventIdArr.length;

		uint[] memory _results = new uint[](_length);

		for (uint i=0; i<_length; i++) {
			_results[i] = uint(_setEventResult(_eventIdArr[i], _resultArr[i]));
		}

		emit LogResultsEvent(_eventIdArr, _results);
	}

	/// @notice Bulk cancel of events
	/// @param _eventIdArr Array of the id of the events to cancel
	function cancelEventBulk (uint[] calldata _eventIdArr) external isAdmin {

		uint _length = _eventIdArr.length;

		uint[] memory _arr = new uint[](_length);

		for (uint i=0; i<_length; i++) {
			_arr[i] = _cancelEvent(_eventIdArr[i]);
		}

		emit LogCancelEvent(_arr);
	}


	/// @notice Open a new offer on the selected event with the parameters passed as arguments
	/// @param _eventId Id of the event the offer is created on
	/// @param _amount Amount the bookmaker is putting on the offer
	/// @param _price Price the bookmaker is selling the offer for
	/// @param _pick Pick of the event the bookmaker is opening the offer on
	function openOffer (uint _eventId, uint _amount, uint _price, uint _pick) external eventAvailable(_eventId) pickValid(_eventId, _pick) {

		require (_amount >= m_minAmount);
		require (_amount <= balances[msg.sender]);
		require (_price >= m_minAmount);

		m_nbOffers = add(m_nbOffers, 1);

		Offer memory newOffer = Offer(m_nbOffers, _eventId, msg.sender, _amount, _price, Pick(_pick), State.OPEN);

		offers[newOffer._id] = newOffer;

		_subBalance(msg.sender, _amount);

		emit LogNewOffer(newOffer._id, newOffer._eventId, newOffer._owner, newOffer._amount, newOffer._price, uint(newOffer._pick));
	}

	/// @notice Update the price of an existing offer
	/// @param _offerId Id of the offer to update
	/// @param _price Price the bookmaker wants to update the offer to
	function updateOffer (uint _offerId, uint _price) external offerAvailable(_offerId) {

		require (offers[_offerId]._owner == msg.sender);
		require (_price >= m_minAmount);

		offers[_offerId]._price = _price;

		emit LogUpdateOffer(offers[_offerId]._id, offers[_offerId]._owner, offers[_offerId]._amount, offers[_offerId]._price);
	}

	/// @notice Close an existing offer
	/// @param _offerId Id of the offer to close
	function closeOffer (uint _offerId) external offerAvailable(_offerId) {

		require (offers[_offerId]._owner == msg.sender);

		_closeOffer(_offerId);
	}

	/// @notice Fully or partly buy an offer and open a bet according to the parameters
	/// @param _offerId Id of the offer to buy
	/// @param _amount Amount the bettor wants to buy the offer with
	function buyOffer (uint _offerId, uint _amount) public offerAvailable(_offerId) {

		require (offers[_offerId]._amount >= m_minAmount);
		require (offers[_offerId]._price >= _amount);
		require (_amount >= m_minAmount);
		require (balances[msg.sender] >= _amount);
		require (uint(events[offers[_offerId]._eventId]._state) == uint(State.OPEN));

		Offer memory offer = offers[_offerId];

		_subBalance(msg.sender, _amount);

		uint _amountBookmaker = div(mul(offer._amount, _amount), offer._price);
		uint _restAmountOffer = sub(offer._amount, _amountBookmaker);
		uint _restPriceOffer = div(mul(_restAmountOffer, offer._price), offer._amount);
		uint _amountToEarn = add(_amountBookmaker, _amount);

		m_nbBets = add(m_nbBets, 1);

		Bet memory newBet = Bet(m_nbBets, offer._eventId, new uint[](0), offer._pick, State.OPEN);

		bets[newBet._id] = newBet;

		Position memory p1 = _createPosition(newBet._id, offer._owner, _amountBookmaker, _amountToEarn, Role.BOOKMAKER);
		Position memory p2 = _createPosition(newBet._id, msg.sender, _amount,  _amountToEarn, Role.BETTOR);

		bets[newBet._id]._positions.push(p1._id);
		bets[newBet._id]._positions.push(p2._id);

		emit LogNewBet(newBet._id, newBet._eventId, bets[newBet._id]._positions, uint(newBet._pick));

		offers[offer._id]._amount = _restAmountOffer;
		offers[offer._id]._price = _restPriceOffer;

		emit LogUpdateOffer(_offerId, offer._owner, _restAmountOffer, _restPriceOffer);

		if(_restAmountOffer < m_minAmount || _restPriceOffer < m_minAmount) {
			_closeOffer(offer._id);
		}
	}

	/// @notice Fully or partly buy multiple offers and open bets according to the parameters
	/// @param _offerIds Ids of the offers to buy
	/// @param _amount Amount the bettor wants to buy the offers with
	function buyOfferBulk (uint[] calldata _offerIds, uint _amount) external {

		require (_amount >= m_minAmount);
		require (balances[msg.sender] >= _amount);

		uint _length = _offerIds.length;
		uint _restAmount = _amount;
		uint _offerAmount;
		uint _offerId;

		for (uint i=0; i<_length; i++) {

			if ( _restAmount < m_minAmount ) {
				break;
			}

			_offerId = _offerIds[i];

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

	/// @notice Update the price of an existing position
	/// @param _positionId Id of the position to update
	/// @param _price Price the user wants to update the position to
	function updatePosition (uint _positionId, uint _price) external {

		require (_positionId <= m_nbPositions);
		require (_price >= m_minAmount);
		require (events[bets[positions[_positionId]._betId]._eventId]._timestampStart > now);
		require (uint(events[bets[positions[_positionId]._betId]._eventId]._state) == uint(State.OPEN));
		require (positions[_positionId]._owner == msg.sender);
		require (positions[_positionId]._amount >= m_minAmount);

		Position memory _position = positions[_positionId];

		_position._price = _price;

		positions[_position._id] = _position;

		emit LogUpdatePosition(_position._id, _position._owner, _position._amount, _position._amountToEarn, _position._price);
	}

	/// @notice Fully or partly buy a position and create a new position in the associated bet
	/// @param _positionId Id of the position the user wants to buy
	/// @param _amount Amount the user wants to buy the position with
	function buyPosition(uint _positionId, uint _amount) external {

		require (balances[msg.sender] >= _amount);
		require (_positionId <= m_nbPositions);
		require (_amount > m_minAmount);
		require (positions[_positionId]._price > m_minAmount);
		require (events[bets[positions[_positionId]._betId]._eventId]._timestampStart < now);
		require (uint(events[bets[positions[_positionId]._betId]._eventId]._state) == uint(State.OPEN));
		require (positions[_positionId]._owner == msg.sender);
		require (positions[_positionId]._amount > m_minAmount);

		Position memory _position = positions[_positionId];
		Bet memory _bet = bets[_position._betId];

		uint _newPositionAmount =  div(mul(_position._amount, _amount), _position._price);
		uint _newPositionAmountToEarn = div(mul(_position._amountToEarn, _amount), _position._price);

		_position._amount = sub(_position._amount, _newPositionAmount);
		_position._amountToEarn = sub(_position._amountToEarn, _newPositionAmountToEarn);
		_position._price = sub(_position._price, _amount);

		positions[_position._id] = _position;

		Position memory p = _createPosition(_position._betId, msg.sender, _newPositionAmount, _newPositionAmountToEarn, _position._role);

		bets[_bet._id]._positions.push(p._id);

		uint _fees = div(mul(_amount, m_tradeFee), 100);

		m_feeBalance = add(m_feeBalance, _fees);

		_subBalance(msg.sender, _amount);
		_addBalance(_position._owner, sub(_amount, _fees));

		emit LogUpdatePosition(_position._id, _position._owner, _position._amount, _position._amountToEarn, _position._price);		
	}

	/// @notice Claim bet earnings of a bet open on a close event
	/// @param _betId Id of the bet to claim from
	function claimBetEarnings(uint _betId) external {

		require (_betId <= m_nbBets);
		require (uint(events[bets[_betId]._eventId]._state) == uint(State.CLOSE));
		require (uint(events[bets[_betId]._eventId]._result) > uint(Pick.NULL));
		require (uint(bets[_betId]._state) == uint(State.OPEN));

		Bet memory _bet = bets[_betId];
		Event memory _event = events[_bet._eventId];
		Position memory _position;

		uint _length = _bet._positions.length;
		uint i;

		if(uint(_event._result) <= uint(Pick.DRAW)) {

			for (i=0; i<_length; i++) {

				_position = positions[_bet._positions[i]];

				if( (_bet._pick == _event._result && _position._role == Role.BETTOR ) || ( _bet._pick != _event._result && _position._role == Role.BOOKMAKER ) ) {

					uint _fees = div(mul(_position._amountToEarn, m_publicFee), 100);
					uint _earnings = sub(_position._amountToEarn, _fees);

					m_feeBalance = add(m_feeBalance, _fees);

					_addBalance(_position._owner, _earnings);
				}
			}
		}

		if(uint(_event._result) == uint(Pick.CANCELED)) {

			for (i=0; i<_length; i++) {
				_position = positions[_bet._positions[i]];
				_addBalance(_position._owner, _position._amount);
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
	/// @param _type Type of the event
	/// @param _ipfsAddress Hash of the JSON containing event details
	/// @param _timestampStart Start timestamp of the event
	function _addEvent(uint _type, bytes32 _ipfsAddress, uint _timestampStart) internal returns(uint _id){

		_id = 0;

		if(_timestampStart > now) {
			if(_type <= uint(Type.HOMEAWAY)) {
				m_nbEvents = add(m_nbEvents, 1);

				Event memory newEvent = Event(m_nbEvents, _ipfsAddress, _timestampStart, Type(_type), Pick.NULL, State.OPEN, 0);

				events[newEvent._id] = newEvent;

				_id = m_nbEvents;
			}
		}
	}

	/// @notice Set result
	/// @param _eventId Id of the event
	/// @param _result Result of the event
	function _setEventResult (uint _eventId, uint _result) private returns (Pick _savedResult) {

		Event memory _event = events[_eventId];

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
		events[_event._id] = _event;

		_savedResult = _event._result;
	}

	/// @notice Cancel event
	/// @param _eventId Id of the event
	function _cancelEvent(uint _eventId) private returns (uint _id) {

		_id = 0;

		if(_eventId <= m_nbEvents && _eventId > 0) {
			Event memory _event = events[_eventId];
			if(uint(_event._state) == uint(State.OPEN)) {
				_event._state = State.CANCELED;
				_id = _event._id;
			}
			events[_event._id] = _event;
		}
	}


	/// @notice Close an existing offer
	/// @param _offerId Id of the offer to close
	function _closeOffer (uint _offerId) private {

		Offer memory offer = offers[_offerId];

		_addBalance(offer._owner, offer._amount);

		offers[_offerId]._amount = 0;
		offers[_offerId]._price = 0;

		offers[_offerId]._state = State.CLOSE;

		emit LogOfferClosed(_offerId, offer._owner);
	}

	/// @notice Create a new Position and adds it to the positions mapping
	/// @param _betId Id of the bet associated to the created position
	/// @param _owner Owner of the created position
	/// @param _amount Amount the owner have in the created position
	/// @param _amountToEarn Amount the owner can earn with the created position
	/// @param _role Role of the owner of the position in the associated bet
	function _createPosition (uint _betId, address _owner, uint _amount, uint _amountToEarn, Role _role) private returns (Position memory newPosition) {

		m_nbPositions = add(m_nbPositions, 1);

		newPosition = Position(m_nbPositions, _betId, _owner, _amount, _amountToEarn, 0, _role);

		positions[newPosition._id] = newPosition;

		emit LogNewPosition(newPosition._id, newPosition._betId, newPosition._owner, newPosition._amount, newPosition._amountToEarn, newPosition._price, uint(newPosition._role));
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

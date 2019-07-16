pragma solidity >=0.4.21 <0.6.0;
pragma experimental ABIEncoderV2;

import "./MaticWETH.sol";


/// @title SocialBet
/// @notice
/// @dev
contract SocialBet {
    /// @notice Owner of SocialBet smart contract
    address payable public owner;

    /**
    * token contract for transfers.
    */
    MaticWETH public weth;

    /// @notice Administrators mapping
    mapping(address => bool) public admins;

    /// @notice Events mapping
    mapping(uint => Event) public events;
    /// @notice Offers mapping
    mapping(uint => Offer) public offers;
    /// @notice Bets mapping
    mapping(uint => Bet) public bets;
    /// @notice Positions mapping
    mapping(uint => Position) public positions;

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

    enum State {OPEN, CLOSE, CANCELED}

    enum Outcome {NULL, CANCELED, HOME, AWAY, DRAW, OVER, UNDER, YES, NO}

    enum BetType {HOMEAWAYDRAW, MONEYLINE, OVERUNDER, POINTSPREAD, BOTHTEAMSCORE, FIRSTTEAMTOSCORE}

    event LogDeposit(address indexed account, uint amount);
    event LogWithdraw(address indexed account, uint amount);
    event LogBalanceChange(address indexed account, uint oldBalance, uint newBalance);
    event LogNewEvent(uint id, bytes32 ipfsAddress, uint[] markets);
    event LogNewMarkets(uint id, uint[] markets);
    event LogResultEvent(uint id);
    event LogCancelEvent(uint id);
    event LogNewOffer(uint id, uint indexed eventId, uint indexed marketIndex, address indexed owner, uint amount, uint price, uint outcome, uint timestampExpiration);
    event LogUpdateOffer(uint indexed id, uint amount, uint price);
    event LogNewBet(uint id, uint indexed eventId, uint indexed marketIndex, uint backPosition, uint layPosition, uint amount, uint outcome);
    event LogBetClosed(uint id);
    event LogNewPosition(uint id, uint indexed betId, address indexed owner, uint amount);

    struct Event {
        uint _id;
        bytes32 _ipfsAddress;
        mapping(uint => Market) _markets;
        State _state;
    }

    struct Market {
        BetType _type;
        bytes10 _data;
        Outcome _outcome;
        bool 	_active;
    }

    struct Offer {
        uint _id;
        uint _eventId;
        uint _marketIndex;
        address _owner;
        uint _amount;
        uint _price;
        Outcome _outcome;
        uint _timestampExpiration;
    }

    struct Bet {
        uint _id;
        uint _eventId;
        uint _marketIndex;
        uint _backPosition;
        uint _layPosition;
        uint _amount;
        Outcome _outcome;
        State _state;
    }

    struct Position {
        uint _id;
        uint _betId;
        address _owner;
        uint _amount;
    }

    /// @dev Check that the caller is the Owner of the smart contract
    modifier isOwner() {
        require(owner == msg.sender, 'Sender it not owner');
        _;
    }

    /// @dev Check that the caller have admin rights
    modifier isAdmin() {
        require(admins[msg.sender], 'Sender is not an admin');
        _;
    }

    /// @dev Check that the event exists, is still open and has not started
    modifier eventAvailable(uint _eventId) {
        require(_eventId > 0, 'Event id should be greater than 0');
        require(_eventId <= m_nbEvents, 'Event id does not exist yet');
        require(uint(events[_eventId]._state) == uint(State.OPEN), 'Event is not open');
        _;
    }

    /// @dev Check that the market exists
    modifier marketAvailable(uint _eventId, uint _marketIndex) {
        require(events[_eventId]._markets[_marketIndex]._active, 'Market is not available');
        _;
    }

    /// @dev Check that the offer exists and is still open
    modifier offerAvailable(uint _offerId) {
        require(_offerId > 0, 'Offer id should be greater than 0');
        require(_offerId <= m_nbOffers, 'Offer id does not exist yet');
        require(offers[_offerId]._timestampExpiration > now, 'Offer is expired');
        require(uint(events[offers[_offerId]._eventId]._state) == uint(State.OPEN), 'Event is not open');
        require(offers[_offerId]._amount >= m_minAmount, 'Offer amount is below minimum');
        require(offers[_offerId]._price >= m_minAmount, 'Offer price is below minimum');
        require(weth.balanceOf(offers[_offerId]._owner) >= m_minAmount, 'Offer owner balance is below minimum');
        require(weth.allowance(offers[_offerId]._owner, address(this)) >= m_minAmount, 'Offer owner allowance is below minimum');
        _;
    }

    /// @dev Check that the selected outcome is valid for the type of the selected event (DRAW is not possible for a HOMEAWAY event)
    modifier outcomeValid(uint _eventId, uint _marketIndex, uint _outcome) {
        if (BetType(_marketIndex) == BetType.HOMEAWAYDRAW) {
            require(_outcome <= uint(Outcome.DRAW), 'Selected outcome is not valid for HOMEAWAYDRAW market');
            require(_outcome >= uint(Outcome.HOME), 'Selected outcome is not valid for HOMEAWAYDRAW market');
        }
        if (BetType(_marketIndex) == BetType.MONEYLINE) {
            require(_outcome <= uint(Outcome.AWAY), 'Selected outcome is not valid for MONEYLINE market');
            require(_outcome >= uint(Outcome.HOME), 'Selected outcome is not valid for MONEYLINE market');
        }
        if (BetType(_marketIndex) == BetType.OVERUNDER) {
            require(_outcome <= uint(Outcome.UNDER), 'Selected outcome is not valid for OVERUNDER market');
            require(_outcome >= uint(Outcome.OVER), 'Selected outcome is not valid for OVERUNDER market');
        }
        if (BetType(_marketIndex) == BetType.POINTSPREAD) {
            require(_outcome <= uint(Outcome.AWAY), 'Selected outcome is not valid for POINTSPREAD market');
            require(_outcome >= uint(Outcome.HOME), 'Selected outcome is not valid for POINTSPREAD market');
        }
        if (BetType(_marketIndex) == BetType.BOTHTEAMSCORE) {
            require(_outcome <= uint(Outcome.NO), 'Selected outcome is not valid for BOTHTEAMSCORE market');
            require(_outcome >= uint(Outcome.YES), 'Selected outcome is not valid for BOTHTEAMSCORE market');
        }
        if (BetType(_marketIndex) == BetType.FIRSTTEAMTOSCORE) {
            require(_outcome <= uint(Outcome.AWAY), 'Selected outcome is not valid for FIRSTTEAMTOSCORE market');
            require(_outcome >= uint(Outcome.HOME), 'Selected outcome is not valid for FIRSTTEAMTOSCORE market');
        }
        _;
    }

    /** 
	@notice Create SocialBet smart contract
	@dev The owner variable is set to the address of the caller of the constructor and the address is set as an admin
	*/
    constructor(address _weth) public {
        owner = msg.sender;
        weth = MaticWETH(_weth);
        addAdmin(msg.sender);
    }

    /**
	@notice Add passed address as an admin
	@dev The value in the admins mapping is set to true at the passed address key
	@param _addr The address to set as an admin
	*/
    function addAdmin(address _addr) public isOwner {
        admins[_addr] = true;
    }

    /// @notice Remove passed address from admins
    /// @dev The value in the admins mapping is set to false at the passed address key
    /// @param _addr The address to unset from admins
    function removeAdmin(address _addr) external isOwner {
        require(_addr != owner, 'Owner can not be removed from admins');
        admins[_addr] = false;
    }

    /// @notice Add new event to smart contract. The details of the event are found in the ipfs address passed
    function addEvent(
        bytes32 _ipfsAddress,
        uint[] calldata _markets,
        bytes10[] calldata _data
        ) external isAdmin {
        uint _id = _addEvent(_ipfsAddress, _markets, _data);

        emit LogNewEvent(_id, _ipfsAddress, _markets);
    }

    function addMarkets(
        uint _eventId,
        uint[] calldata _markets,
        bytes10[] calldata _data
        ) external isAdmin eventAvailable(_eventId) {
        _addMarkets(_eventId, _markets, _data);

        emit LogNewMarkets(_eventId, _markets);
    }

    /// @notice Set events result
    function setEventResult(uint _eventId, uint[] calldata _markets, uint[] calldata _outcomes)
    external
    isAdmin
    {
        _setEventResult(_eventId, _markets, _outcomes);

        emit LogResultEvent(_eventId);
    }

    /// @notice Cancel an event
    function cancelEvent(uint _eventId) 
    external 
    isAdmin
    {
        _cancelEvent(_eventId);

        emit LogCancelEvent(_eventId);
    }

    /// @notice Open a new offer on the selected event with the parameters passed as arguments
    /// @param _eventId Id of the event the offer is created on
    /// @param _amount Amount the bookmaker is putting on the offer
    /// @param _price Price the bookmaker is selling the offer for
    /// @param _outcome Outcome of the event the bookmaker is opening the offer on
    function openOffer(
        uint _eventId,
        uint _marketIndex,
        uint _amount,
        uint _price,
        uint _outcome,
        uint _timestampExpiration
        )
    external
    eventAvailable(_eventId)
    marketAvailable(_eventId, _marketIndex)
    outcomeValid(_eventId, _marketIndex, _outcome)
    {
        require(_price >= m_minAmount, 'Price is below minimum');
        require(_amount >= m_minAmount, 'Amount is below minimum');
        require(_timestampExpiration >= now, 'Expiration timestamp is in the past');

        m_nbOffers = add(m_nbOffers, 1);

        Offer memory newOffer = Offer(
            m_nbOffers,
            _eventId,
            _marketIndex,
            msg.sender,
            _amount,
            _price,
            Outcome(_outcome),
            _timestampExpiration
            );

        offers[newOffer._id] = newOffer;

        emit LogNewOffer(
            newOffer._id,
            newOffer._eventId,
            newOffer._marketIndex,
            newOffer._owner,
            newOffer._amount,
            newOffer._price,
            uint(newOffer._outcome),
            newOffer._timestampExpiration
            );
    }

    /// @notice Close an existing offer
    /// @param _offerId Id of the offer to close
    function closeOffer(uint _offerId) external {
        require(_offerId > 0, 'Offer id should be greater than 0');
        require(_offerId <= m_nbOffers, 'Offer id does not exist yet');
        require(offers[_offerId]._owner == msg.sender, 'Offer owner is not sender');
        require(offers[_offerId]._amount > 0, 'Offer is already closed');

        _closeOffer(_offerId);
    }

    /// @notice Fully or partly buy an offer and open a bet according to the parameters
    /// @param _offerId Id of the offer to buy
    /// @param _amount Amount the bettor wants to buy the offer with
    function buyOffer(uint _offerId, uint _amount)
    public
    offerAvailable(_offerId)
    {
        require(_amount >= m_minAmount, 'Amount is below minimum');
        require(weth.balanceOf(msg.sender) >= _amount, 'Amount exceeds sender balance');
        require(weth.allowance(msg.sender, address(this)) >= _amount, 'Amount exceeds sender allowance');

        Offer memory _offer = offers[_offerId];

        uint _amountBuyer = _amount;

        if ( _offer._price < _amount ) {
        	_amountBuyer = _offer._price;
        }

        uint _amountOfferToBet = div( mul( _offer._amount, _amountBuyer ), _offer._price );

        uint _balanceOwner = weth.balanceOf(_offer._owner);
        uint _allowanceOwner = weth.allowance(_offer._owner, address(this));

        uint _amountAvailableOwner = _balanceOwner > _allowanceOwner ? _allowanceOwner : _balanceOwner;

        if( _amountAvailableOwner < _amountOfferToBet ) {
        	_amountOfferToBet = _amountAvailableOwner;
        	_amountBuyer = div( mul( _amountOfferToBet, _offer._price ), _offer._amount );
        }
        
        uint _restAmountOffer = sub( _offer._amount, _amountOfferToBet );
        uint _restPriceOffer = div( mul( _restAmountOffer, _offer._price ), _offer._amount );

        weth.transferFrom(msg.sender, address(this), _amountBuyer);
        weth.transferFrom(_offer._owner, address(this), _amountOfferToBet);

        m_nbBets = add(m_nbBets, 1);

        Bet memory _newBet;
        _newBet._id = m_nbBets;
        _newBet._eventId = _offer._eventId;
        _newBet._marketIndex = _offer._marketIndex;
        _newBet._outcome = _offer._outcome;
        _newBet._state = State.OPEN;

        Position memory backPosition = _createPosition(
            _newBet._id,
            msg.sender,
            _amountBuyer
            );
        Position memory layPosition = _createPosition(
            _newBet._id,
            _offer._owner,
            _amountOfferToBet
            );

        _newBet._backPosition = backPosition._id;
        _newBet._layPosition = layPosition._id;
        _newBet._amount = backPosition._amount + layPosition._amount;

        bets[m_nbBets] = _newBet;

        emit LogNewBet(
            _newBet._id,
            _newBet._eventId,
            _newBet._marketIndex,
            _newBet._backPosition,
            _newBet._layPosition,
            _newBet._amount,
            uint(_newBet._outcome)
            );

        offers[_offer._id]._amount = _restAmountOffer;
        offers[_offer._id]._price = _restPriceOffer;

        if (_restAmountOffer < m_minAmount || _restPriceOffer < m_minAmount) {
            _closeOffer(_offer._id);
        }
        else {
            emit LogUpdateOffer(_offerId, _restAmountOffer, _restPriceOffer);
        }
    }

    /// @notice Fully or partly buy multiple offers and open bets according to the parameters
    /// @param _offerIdArr Array of the id of the offers to buy
    /// @param _amount Amount the bettor wants to buy the offers with
    function buyOfferBulk(
        uint[] calldata _offerIdArr,
        uint _amount
        ) external {
        require(_amount >= m_minAmount, 'Amount is below minimum');
        require(weth.balanceOf(msg.sender) >= _amount, 'Amount exceeds sender balance');

        uint _length = _offerIdArr.length;
        uint _restAmount = _amount;
        uint _offerAmount;
        uint _offerId;

        for (uint i = 0; i < _length; i++) {
            if (_restAmount < m_minAmount) {
                break;
            }

            _offerId = _offerIdArr[i];

            if (offers[_offerId]._price <= _restAmount) {
                _offerAmount = offers[_offerId]._price;
                } else {
                    _offerAmount = _restAmount;
                }

                buyOffer(_offerId, _offerAmount);

                _restAmount = sub(_restAmount, _offerAmount);
            }
        }

    /// @notice Claim bet earnings of a bet open on a close event
    function claimBetEarnings(uint _betId) external {
        require(_betId > 0, 'Bet id should be greater than 0');
        require(_betId <= m_nbBets, 'Bet id does not exist');
        require(uint(bets[_betId]._state) == uint(State.OPEN), 'Bet is not open');
        require(uint(events[bets[_betId]._eventId]._state) > uint(State.OPEN), 'Event is still open');

        Bet memory _bet = bets[_betId];
        Event storage _event = events[_bet._eventId];

        if (uint(_event._state) == uint(State.CANCELED)) {
            weth.transfer(positions[_bet._backPosition]._owner, positions[_bet._backPosition]._amount);
            weth.transfer(positions[_bet._layPosition]._owner, positions[_bet._layPosition]._amount);
        } 
        else {
            if (_event._markets[_bet._marketIndex]._outcome == _bet._outcome) {
                weth.transfer(positions[_bet._backPosition]._owner, _bet._amount);
            } 
            else if (_event._markets[_bet._marketIndex]._outcome != _bet._outcome) {
                weth.transfer(positions[_bet._layPosition]._owner, _bet._amount);
            }
        }

        _bet._state = State.CLOSE;
        bets[_bet._id] = _bet;

        emit LogBetClosed(_bet._id);
    }

    function getMarket(uint _eventId, uint _marketId) public view returns (Market memory) {
        return events[_eventId]._markets[_marketId];
    }

    /// @notice Add event
    /// @param _ipfsAddress Hash of the JSON containing event details
    function _addEvent(
        bytes32 _ipfsAddress,
        uint[] memory _markets,
        bytes10[] memory _data
        ) internal returns (uint _id) {
        m_nbEvents = add(m_nbEvents, 1);

        Event memory newEvent;
        newEvent._id = m_nbEvents;
        newEvent._ipfsAddress = _ipfsAddress;
        newEvent._state = State.OPEN;

        events[newEvent._id] = newEvent;

        _addMarkets(newEvent._id, _markets, _data);

        _id = m_nbEvents;
    }

    function _addMarkets(
        uint _eventId,
        uint[] memory _markets,
        bytes10[] memory _data
        ) internal {
        for (uint i = 0; i < _markets.length; i++) {
            events[_eventId]._markets[_markets[i]] = (Market(
                BetType(_markets[i]),
                _data[i],
                Outcome.NULL,
                true
                ));
        }
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
    function _setEventResult(uint _eventId, uint[] memory _markets, uint[] memory _result) private {
        Event storage _event = events[_eventId];

        if (uint(_event._state) != uint(State.CLOSE)) {
            for (uint i = 0; i < _markets.length; i++) {
                _event._markets[_markets[i]]._outcome = Outcome(_result[i]);
            }
            _event._state = State.CLOSE;
        }
    }

    /// @notice Close an existing offer
    /// @param _offerId Id of the offer to close
    function _closeOffer(uint _offerId) private {
        offers[_offerId]._amount = 0;
        offers[_offerId]._price = 0;

        emit LogUpdateOffer(_offerId, offers[_offerId]._amount, offers[_offerId]._price);
    }

    /// @notice Create a new Position and adds it to the positions mapping
    /// @param _betId Id of the bet associated to the created position
    /// @param _owner Owner of the created position
    /// @param _amount Amount the owner have in the created position
    function _createPosition(
        uint _betId,
        address _owner,
        uint _amount
        ) private returns (Position memory newPosition) {
        m_nbPositions = add(m_nbPositions, 1);

        newPosition = Position(m_nbPositions, _betId, _owner, _amount);

        positions[newPosition._id] = newPosition;

        _logNewPosition(newPosition);
    }

    function _logNewPosition(Position memory newPosition) private {
        emit LogNewPosition(
            newPosition._id,
            newPosition._betId,
            newPosition._owner,
            newPosition._amount
            );
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

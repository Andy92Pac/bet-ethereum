pragma solidity >=0.4.21 <0.6.0;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./MaticWETH.sol";

/// @title SocialBet contract
/// @author Andy Mpondo Black
/// @notice This contract is used for SocialBet decentralized sports betting platform
/// @dev This contract interact with WETH ERC-20 token contract
contract SocialBet {

    using SafeMath for uint;

    /***************************************************************************
     *                      Variables, Constants & Enums                       *
     ***************************************************************************/

    /// @notice Owner of SocialBet smart contract
    address payable public owner;

    /// @notice token contract for transfers
    MaticWETH public Token;

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

    /// @notice Minimum ammount to maintain an Offer open to sell
    uint public m_minAmount = 10000000000000000;

    enum State {OPEN, CLOSE, CANCELED}

    enum Outcome {NULL, CANCELED, HOME, AWAY, DRAW, OVER, UNDER, YES, NO}

    enum BetType {HOMEAWAYDRAW, MONEYLINE, OVERUNDER, POINTSPREAD, BOTHTEAMSCORE, FIRSTTEAMTOSCORE}

    /***************************************************************************
     *                                 Events                                  *
     ***************************************************************************/

    /**
     * Event for new event creation
     * @param id Id of the created event
     * @param ipfsAddress Ipfs hash of the created event
     * @param markets Markets of the created event
     */
     event LogNewEvent(uint id, bytes32 ipfsAddress, uint[] markets);

    /**
     * Event for new markets adding
     * @param id Id of the event
     * @param markets Markets added to the event
     */
     event LogNewMarkets(uint id, uint[] markets);

    /**
     * Event for finalized event
     * @param id Id of the event
     */
     event LogResultEvent(uint id);

    /**
     * Event for canceled event
     * @param id Id of the event
     */
     event LogCancelEvent(uint id);

    /**
     * Event for new offer creation
     * @param id Id of the created offer
     * @param eventId Id of the event
     * @param marketIndex Index of the market
     * @param owner Address of the owner
     * @param amount Amount of the offer
     * @param price Price of the offer
     * @param outcome Outcome of the offer
     * @param timestampExpiration Timestamp of expiration of the offer
     */
     event LogNewOffer(uint id, uint indexed eventId, uint indexed marketIndex, address indexed owner, uint amount, uint price, uint outcome, uint timestampExpiration);

    /**
     * Event for updated offer
     * @param id Id of the updated offer
     * @param amount Amount of the offer
     * @param price Price of the offer
     */
     event LogUpdateOffer(uint indexed id, uint amount, uint price);

    /**
     * Event for new bet creation
     * @param id Id of the created bet
     * @param eventId Id of the event
     * @param marketIndex Index of the market
     * @param backPosition Id of the back position of the bet
     * @param layPosition Id of the lay position of the bet
     * @param amount Amount of the bet
     * @param outcome Outcome of the bet
     */
     event LogNewBet(uint id, uint indexed eventId, uint indexed marketIndex, uint backPosition, uint layPosition, uint amount, uint outcome);

    /**
     * Event for closed bet
     * @param id Id of the closed bet
     */
     event LogBetClosed(uint id);

    /**
     * Event for new position creation
     * @param id Id of the created position
     * @param betId Id of the bet
     * @param owner Owner of the position
     * @param amount Amount of the position
     */
     event LogNewPosition(uint id, uint indexed betId, address indexed owner, uint amount);

    /***************************************************************************
     *                               Structures                                *
     ***************************************************************************/

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

    /***************************************************************************
     *                                Modifiers                                *
     ***************************************************************************/

    /// @notice Check that the caller is the owner of the smart contract
    modifier isOwner() {
        require(owner == msg.sender, 'Sender it not owner');
        _;
    }

    /// @notice Check that the caller have admin rights
    modifier isAdmin() {
        require(admins[msg.sender], 'Sender is not an admin');
        _;
    }

    /// @notice Check that the event exists and is still open
    modifier eventAvailable(uint _eventId) {
        require(_eventId > 0, 'Event id should be greater than 0');
        require(_eventId <= m_nbEvents, 'Event id does not exist yet');
        require(uint(events[_eventId]._state) == uint(State.OPEN), 'Event is not open');
        _;
    }

    /// @notice Check that the market exists in the selected event
    modifier marketAvailable(uint _eventId, uint _marketIndex) {
        require(events[_eventId]._markets[_marketIndex]._active, 'Market is not available');
        _;
    }

    /// @notice Check that the offer exists and is still open
    modifier offerAvailable(uint _offerId) {
        require(_offerId > 0, 'Offer id should be greater than 0');
        require(_offerId <= m_nbOffers, 'Offer id does not exist yet');
        require(offers[_offerId]._timestampExpiration > now, 'Offer is expired');
        require(uint(events[offers[_offerId]._eventId]._state) == uint(State.OPEN), 'Event is not open');
        require(offers[_offerId]._amount >= m_minAmount, 'Offer amount is below minimum');
        require(offers[_offerId]._price >= m_minAmount, 'Offer price is below minimum');
        require(Token.balanceOf(offers[_offerId]._owner) >= m_minAmount, 'Offer owner balance is below minimum');
        require(Token.allowance(offers[_offerId]._owner, address(this)) >= m_minAmount, 'Offer owner allowance is below minimum');
        _;
    }

    /// @notice Check that the selected outcome is valid for the type of the selected event
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

    /***************************************************************************
     *                               Constructor                               *
     ***************************************************************************/

    /** 
	* @notice Constructor, take _tokenAddress
    * @param _tokenAddress Address of the token used
    */
    constructor(address _tokenAddress) public {
        owner = msg.sender;
        Token = MaticWETH(_tokenAddress);
        addAdmin(msg.sender);
    }

    /***************************************************************************
     *                             Owner functions                             *
     ***************************************************************************/

    /**
	* @notice Set address as an admin
	* @param _addr The address to set as an admin
	*/
    function addAdmin(address _addr) public isOwner {
        admins[_addr] = true;
    }

    /**
    * @notice Remove address from admins
    * @param _addr The address to unset from admins
    */
    function removeAdmin(address _addr) external isOwner {
        require(_addr != owner, 'Owner can not be removed from admins');
        admins[_addr] = false;
    }

    /***************************************************************************
     *                             Admin functions                             *
     ***************************************************************************/

    /**
    * @notice Add new event to smart contract. The details of the event are found in the ipfs address
    * @param _ipfsAddress Ipfs address containing informations about the Event
    * @param _markets Markets available for the Event
    * @param _data Additionnal data about the Markets
    */
    function addEvent(
        bytes32 _ipfsAddress,
        uint[] calldata _markets,
        bytes10[] calldata _data
        ) external isAdmin {
        uint _id = _addEvent(_ipfsAddress, _markets, _data);

        emit LogNewEvent(_id, _ipfsAddress, _markets);
    }

    /**
    * @notice Add new markets to existing event
    * @param _eventId Id of the Event
    * @param _markets Markets available for the Event
    * @param _data Additionnal data about the Markets
    */
    function addMarkets(
        uint _eventId,
        uint[] calldata _markets,
        bytes10[] calldata _data
        ) external isAdmin eventAvailable(_eventId) {
        _addMarkets(_eventId, _markets, _data);

        emit LogNewMarkets(_eventId, _markets);
    }

    /**
    * @notice Set results to an event markets
    * @param _eventId Id of the Event
    * @param _markets Markets to set results to
    * @param _outcomes Outcomes of the Markets
    */
    function setEventResult(uint _eventId, uint[] calldata _markets, uint[] calldata _outcomes)
    external
    isAdmin
    eventAvailable(_eventId)
    {
        _setEventResult(_eventId, _markets, _outcomes);

        emit LogResultEvent(_eventId);
    }

    /**
    * @notice Cancel an event
    * @param _eventId Id of the Event
    */
    function cancelEvent(uint _eventId) 
    external 
    isAdmin
    eventAvailable(_eventId)
    {
        _cancelEvent(_eventId);

        emit LogCancelEvent(_eventId);
    }

    /***************************************************************************
     *                            External functions                           *
     ***************************************************************************/

    /**
    * @notice Open a new offer
    * @param _eventId Id of the Event
    * @param _marketIndex Index of the Market
    * @param _amount Amount the bookmaker is putting on the Offer
    * @param _price Price the bookmaker is selling the Offer for
    * @param _outcome Outcome of the market the bookmaker is opening the Offer on
    * @param _timestampExpiration timestamp the Offer expires on
    */
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

        m_nbOffers = m_nbOffers.add(1);

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

    /**
    * @notice Close an offer
    * @param _offerId Id of the Offer
    */
    function closeOffer(uint _offerId) external {
        require(_offerId > 0, 'Offer id should be greater than 0');
        require(_offerId <= m_nbOffers, 'Offer id does not exist yet');
        require(offers[_offerId]._owner == msg.sender, 'Offer owner is not sender');
        require(offers[_offerId]._amount > 0, 'Offer is already closed');

        _closeOffer(_offerId);
    }

    /**
    * @notice Buy an offer
    * @param _offerId Id of the Offer
    * @param _amount Amount you're buying the Offer with
    */
    function buyOffer(uint _offerId, uint _amount)
    public
    offerAvailable(_offerId)
    {
        require(_amount >= m_minAmount, 'Amount is below minimum');
        require(Token.balanceOf(msg.sender) >= _amount, 'Amount exceeds sender balance');
        require(Token.allowance(msg.sender, address(this)) >= _amount, 'Amount exceeds sender allowance');

        Offer memory _offer = offers[_offerId];

        uint _amountBuyer = _amount;

        if ( _offer._price < _amount ) {
        	_amountBuyer = _offer._price;
        }

        uint _amountOfferToBet = _offer._amount.mul(_amountBuyer).div(_offer._price);

        uint _balanceOwner = Token.balanceOf(_offer._owner);
        uint _allowanceOwner = Token.allowance(_offer._owner, address(this));

        uint _amountAvailableOwner = _balanceOwner > _allowanceOwner ? _allowanceOwner : _balanceOwner;

        if( _amountAvailableOwner < _amountOfferToBet ) {
        	_amountOfferToBet = _amountAvailableOwner;
        	_amountBuyer = _amountOfferToBet.mul(_offer._price).div(_offer._amount);
        }
        
        uint _restAmountOffer = _offer._amount.sub(_amountOfferToBet);
        uint _restPriceOffer = _restAmountOffer.mul(_offer._price).div(_offer._amount);

        Token.transferFrom(msg.sender, address(this), _amountBuyer);
        Token.transferFrom(_offer._owner, address(this), _amountOfferToBet);

        m_nbBets = m_nbBets.add(1);

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

    /**
    * @notice Buy multiple offers
    * @param _offerIds Offers to buy
    * @param _amount Amount you're buying the Offers with
    */
    function buyOfferBulk(
        uint[] calldata _offerIds,
        uint _amount
        ) external {
        require(_amount >= m_minAmount, 'Amount is below minimum');
        require(Token.balanceOf(msg.sender) >= _amount, 'Amount exceeds sender balance');
        require(Token.allowance(msg.sender, address(this)) >= _amount, 'Amount exceeds sender allowance');

        uint _length = _offerIds.length;
        uint _restAmount = _amount;
        uint _offerAmount;
        uint _offerId;

        for (uint i = 0; i < _length; i++) {
            if (_restAmount < m_minAmount) {
                break;
            }

            _offerId = _offerIds[i];

            if (offers[_offerId]._price <= _restAmount) {
                _offerAmount = offers[_offerId]._price;
                } else {
                    _offerAmount = _restAmount;
                }

                buyOffer(_offerId, _offerAmount);

                _restAmount = _restAmount.sub(_offerAmount);
            }
        }

    /**
    * @notice Close a bet and send earnings to winner
    * @param _betId Id of the Bet to close
    */
    function claimBetEarnings(uint _betId) external {
        require(_betId > 0, 'Bet id should be greater than 0');
        require(_betId <= m_nbBets, 'Bet id does not exist');
        require(uint(bets[_betId]._state) == uint(State.OPEN), 'Bet is not open');
        require(uint(events[bets[_betId]._eventId]._state) > uint(State.OPEN), 'Event is still open');

        Bet memory _bet = bets[_betId];
        Event storage _event = events[_bet._eventId];

        if (uint(_event._state) == uint(State.CANCELED)) {
            Token.transfer(positions[_bet._backPosition]._owner, positions[_bet._backPosition]._amount);
            Token.transfer(positions[_bet._layPosition]._owner, positions[_bet._layPosition]._amount);
        } 
        else {
            if (_event._markets[_bet._marketIndex]._outcome == _bet._outcome) {
                Token.transfer(positions[_bet._backPosition]._owner, _bet._amount);
            } 
            else if (_event._markets[_bet._marketIndex]._outcome != _bet._outcome) {
                Token.transfer(positions[_bet._layPosition]._owner, _bet._amount);
            }
        }

        _bet._state = State.CLOSE;
        bets[_bet._id] = _bet;

        emit LogBetClosed(_bet._id);
    }

    /**
    * @notice Returns a market
    * @param _eventId Id of the Event
    * @param _marketIndex Index of the Market
    */
    function getMarket(uint _eventId, uint _marketIndex) public view returns (Market memory) {
        return events[_eventId]._markets[_marketIndex];
    }

    /***************************************************************************
     *                             Private functions                           *
     ***************************************************************************/

    /**
    * @notice Private function that create an Event and add it to the mapping
    * @param _ipfsAddress Ipfs address containing informations about the Event
    * @param _markets Markets available for the Event
    * @param _data Additionnal data about the Markets
    */
    function _addEvent(
        bytes32 _ipfsAddress,
        uint[] memory _markets,
        bytes10[] memory _data
        ) private returns (uint _id) {
        m_nbEvents = m_nbEvents.add(1);

        Event memory newEvent;
        newEvent._id = m_nbEvents;
        newEvent._ipfsAddress = _ipfsAddress;
        newEvent._state = State.OPEN;

        events[newEvent._id] = newEvent;

        _addMarkets(newEvent._id, _markets, _data);

        _id = m_nbEvents;
    }

    /**
    * @notice Private function that add new markets to existing event
    * @param _eventId Id of the Event
    * @param _markets Markets available for the Event
    * @param _data Additionnal data about the Markets
    */
    function _addMarkets(
        uint _eventId,
        uint[] memory _markets,
        bytes10[] memory _data
        ) private {
        for (uint i = 0; i < _markets.length; i++) {
            events[_eventId]._markets[_markets[i]] = (Market(
                BetType(_markets[i]),
                _data[i],
                Outcome.NULL,
                true
                ));
        }
    }

    /**
    * @notice Private function that set results to an event markets
    * @param _eventId Id of the Event
    * @param _markets Markets to set results to
    * @param _outcomes Outcomes of the Markets
    */
    function _setEventResult(uint _eventId, uint[] memory _markets, uint[] memory _outcomes) private {
        Event storage _event = events[_eventId];

        if (uint(_event._state) == uint(State.OPEN)) {
            for (uint i = 0; i < _markets.length; i++) {
                _event._markets[_markets[i]]._outcome = Outcome(_outcomes[i]);
            }
            _event._state = State.CLOSE;
        }
    }

    /**
    * @notice Private function that cancel an event
    * @param _eventId Id of the Event
    */
    function _cancelEvent(uint _eventId) private {
        Event memory _event = events[_eventId];

        _event._state = State.CANCELED;

        events[_event._id] = _event;
    }

    /**
    * @notice Private function that close an offer
    * @param _offerId Id of the Offer
    */
    function _closeOffer(uint _offerId) private {
        offers[_offerId]._amount = 0;
        offers[_offerId]._price = 0;

        emit LogUpdateOffer(_offerId, offers[_offerId]._amount, offers[_offerId]._price);
    }

    /**
    * @notice Private function that create a Position and add it to the mapping 
    * @param _betId Id of the related Bet
    * @param _owner Owner of the Position
    * @param _amount Amount of the Position
    */
    function _createPosition(
        uint _betId,
        address _owner,
        uint _amount
        ) private returns (Position memory newPosition) {
        m_nbPositions = m_nbPositions.add(1);

        newPosition = Position(m_nbPositions, _betId, _owner, _amount);

        positions[newPosition._id] = newPosition;

        _logNewPosition(newPosition);
    }

    /**
    * @notice Emits the logNewPosition event  
    * @param _newPosition Position to log
    */
    function _logNewPosition(Position memory _newPosition) private {
        emit LogNewPosition(
            _newPosition._id,
            _newPosition._betId,
            _newPosition._owner,
            _newPosition._amount
            );
    }
}

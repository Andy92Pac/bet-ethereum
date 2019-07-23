pragma solidity >=0.4.21 <0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     /**
     * @dev Destoys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

contract WETH is ERC20 {
  event Deposit(address indexed dst, uint256 wad);
  event Withdrawal(address indexed src, uint256 wad);

  function deposit() public payable;

  function withdraw(uint256 wad) public;

  function withdraw(uint256 wad, address payable user) public;
}

contract MaticWETH is WETH {
  string public name = "Wrapped Ether";
  string public symbol = "WETH";
  uint8  public decimals = 18;

  function deposit() public payable {
    _mint(msg.sender, msg.value);
    emit Deposit(msg.sender, msg.value);
  }

  function withdraw(uint wad) public {
    require(balanceOf(msg.sender) >= wad);
    _burn(msg.sender, wad);
    msg.sender.transfer(wad);
    emit Withdrawal(msg.sender, wad);
  }

  function withdraw(uint wad, address payable user) public {
    require(balanceOf(msg.sender) >= wad);
    user.transfer(wad);
    _burn(msg.sender, wad);
    emit Withdrawal(user, wad);
  }
}

pragma experimental ABIEncoderV2;




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
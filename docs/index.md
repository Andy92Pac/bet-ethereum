[SocialBet]: #SocialBet
[SocialBet-isOwner--]: #SocialBet-isOwner--
[SocialBet-isAdmin--]: #SocialBet-isAdmin--
[SocialBet-eventAvailable-uint256-]: #SocialBet-eventAvailable-uint256-
[SocialBet-marketAvailable-uint256-uint256-]: #SocialBet-marketAvailable-uint256-uint256-
[SocialBet-offerAvailable-uint256-]: #SocialBet-offerAvailable-uint256-
[SocialBet-outcomeValid-uint256-uint256-uint256-]: #SocialBet-outcomeValid-uint256-uint256-uint256-
[SocialBet-constructor-address-]: #SocialBet-constructor-address-
[SocialBet-addAdmin-address-]: #SocialBet-addAdmin-address-
[SocialBet-removeAdmin-address-]: #SocialBet-removeAdmin-address-
[SocialBet-addEvent-bytes32-uint256---bytes10---]: #SocialBet-addEvent-bytes32-uint256---bytes10---
[SocialBet-addMarkets-uint256-uint256---bytes10---]: #SocialBet-addMarkets-uint256-uint256---bytes10---
[SocialBet-setEventResult-uint256-uint256---uint256---]: #SocialBet-setEventResult-uint256-uint256---uint256---
[SocialBet-cancelEvent-uint256-]: #SocialBet-cancelEvent-uint256-
[SocialBet-openOffer-uint256-uint256-uint256-uint256-uint256-uint256-]: #SocialBet-openOffer-uint256-uint256-uint256-uint256-uint256-uint256-
[SocialBet-closeOffer-uint256-]: #SocialBet-closeOffer-uint256-
[SocialBet-buyOffer-uint256-uint256-]: #SocialBet-buyOffer-uint256-uint256-
[SocialBet-buyOfferBulk-uint256---uint256-]: #SocialBet-buyOfferBulk-uint256---uint256-
[SocialBet-claimBetEarnings-uint256-]: #SocialBet-claimBetEarnings-uint256-
[SocialBet-getMarket-uint256-uint256-]: #SocialBet-getMarket-uint256-uint256-
[SocialBet-LogNewEvent-uint256-bytes32-uint256---]: #SocialBet-LogNewEvent-uint256-bytes32-uint256---
[SocialBet-LogNewMarkets-uint256-uint256---]: #SocialBet-LogNewMarkets-uint256-uint256---
[SocialBet-LogResultEvent-uint256-]: #SocialBet-LogResultEvent-uint256-
[SocialBet-LogCancelEvent-uint256-]: #SocialBet-LogCancelEvent-uint256-
[SocialBet-LogNewOffer-uint256-uint256-uint256-address-uint256-uint256-uint256-uint256-]: #SocialBet-LogNewOffer-uint256-uint256-uint256-address-uint256-uint256-uint256-uint256-
[SocialBet-LogUpdateOffer-uint256-uint256-uint256-]: #SocialBet-LogUpdateOffer-uint256-uint256-uint256-
[SocialBet-LogNewBet-uint256-uint256-uint256-uint256-uint256-uint256-uint256-]: #SocialBet-LogNewBet-uint256-uint256-uint256-uint256-uint256-uint256-uint256-
[SocialBet-LogBetClosed-uint256-]: #SocialBet-LogBetClosed-uint256-
[SocialBet-LogNewPosition-uint256-uint256-address-uint256-]: #SocialBet-LogNewPosition-uint256-uint256-address-uint256-

## <span id="SocialBet"></span> `SocialBet`



- [`isOwner()`][SocialBet-isOwner--]
- [`isAdmin()`][SocialBet-isAdmin--]
- [`eventAvailable(uint256 _eventId)`][SocialBet-eventAvailable-uint256-]
- [`marketAvailable(uint256 _eventId, uint256 _marketIndex)`][SocialBet-marketAvailable-uint256-uint256-]
- [`offerAvailable(uint256 _offerId)`][SocialBet-offerAvailable-uint256-]
- [`outcomeValid(uint256 _eventId, uint256 _marketIndex, uint256 _outcome)`][SocialBet-outcomeValid-uint256-uint256-uint256-]
- [`constructor(address _tokenAddress)`][SocialBet-constructor-address-]
- [`addAdmin(address _addr)`][SocialBet-addAdmin-address-]
- [`removeAdmin(address _addr)`][SocialBet-removeAdmin-address-]
- [`addEvent(bytes32 _ipfsAddress, uint256[] _markets, bytes10[] _data)`][SocialBet-addEvent-bytes32-uint256---bytes10---]
- [`addMarkets(uint256 _eventId, uint256[] _markets, bytes10[] _data)`][SocialBet-addMarkets-uint256-uint256---bytes10---]
- [`setEventResult(uint256 _eventId, uint256[] _markets, uint256[] _outcomes)`][SocialBet-setEventResult-uint256-uint256---uint256---]
- [`cancelEvent(uint256 _eventId)`][SocialBet-cancelEvent-uint256-]
- [`openOffer(uint256 _eventId, uint256 _marketIndex, uint256 _amount, uint256 _price, uint256 _outcome, uint256 _timestampExpiration)`][SocialBet-openOffer-uint256-uint256-uint256-uint256-uint256-uint256-]
- [`closeOffer(uint256 _offerId)`][SocialBet-closeOffer-uint256-]
- [`buyOffer(uint256 _offerId, uint256 _amount)`][SocialBet-buyOffer-uint256-uint256-]
- [`buyOfferBulk(uint256[] _offerIds, uint256 _amount)`][SocialBet-buyOfferBulk-uint256---uint256-]
- [`claimBetEarnings(uint256 _betId)`][SocialBet-claimBetEarnings-uint256-]
- [`getMarket(uint256 _eventId, uint256 _marketIndex)`][SocialBet-getMarket-uint256-uint256-]
- [`LogNewEvent(uint256 id, bytes32 ipfsAddress, uint256[] markets)`][SocialBet-LogNewEvent-uint256-bytes32-uint256---]
- [`LogNewMarkets(uint256 id, uint256[] markets)`][SocialBet-LogNewMarkets-uint256-uint256---]
- [`LogResultEvent(uint256 id)`][SocialBet-LogResultEvent-uint256-]
- [`LogCancelEvent(uint256 id)`][SocialBet-LogCancelEvent-uint256-]
- [`LogNewOffer(uint256 id, uint256 eventId, uint256 marketIndex, address owner, uint256 amount, uint256 price, uint256 outcome, uint256 timestampExpiration)`][SocialBet-LogNewOffer-uint256-uint256-uint256-address-uint256-uint256-uint256-uint256-]
- [`LogUpdateOffer(uint256 id, uint256 amount, uint256 price)`][SocialBet-LogUpdateOffer-uint256-uint256-uint256-]
- [`LogNewBet(uint256 id, uint256 eventId, uint256 marketIndex, uint256 backPosition, uint256 layPosition, uint256 amount, uint256 outcome)`][SocialBet-LogNewBet-uint256-uint256-uint256-uint256-uint256-uint256-uint256-]
- [`LogBetClosed(uint256 id)`][SocialBet-LogBetClosed-uint256-]
- [`LogNewPosition(uint256 id, uint256 betId, address owner, uint256 amount)`][SocialBet-LogNewPosition-uint256-uint256-address-uint256-]
### <span id="SocialBet-isOwner--"></span> `isOwner()`



### <span id="SocialBet-isAdmin--"></span> `isAdmin()`



### <span id="SocialBet-eventAvailable-uint256-"></span> `eventAvailable(uint256 _eventId)`



### <span id="SocialBet-marketAvailable-uint256-uint256-"></span> `marketAvailable(uint256 _eventId, uint256 _marketIndex)`



### <span id="SocialBet-offerAvailable-uint256-"></span> `offerAvailable(uint256 _offerId)`



### <span id="SocialBet-outcomeValid-uint256-uint256-uint256-"></span> `outcomeValid(uint256 _eventId, uint256 _marketIndex, uint256 _outcome)`



### <span id="SocialBet-constructor-address-"></span> `constructor(address _tokenAddress)` (public)



### <span id="SocialBet-addAdmin-address-"></span> `addAdmin(address _addr)` (public)



### <span id="SocialBet-removeAdmin-address-"></span> `removeAdmin(address _addr)` (external)



### <span id="SocialBet-addEvent-bytes32-uint256---bytes10---"></span> `addEvent(bytes32 _ipfsAddress, uint256[] _markets, bytes10[] _data)` (external)



### <span id="SocialBet-addMarkets-uint256-uint256---bytes10---"></span> `addMarkets(uint256 _eventId, uint256[] _markets, bytes10[] _data)` (external)



### <span id="SocialBet-setEventResult-uint256-uint256---uint256---"></span> `setEventResult(uint256 _eventId, uint256[] _markets, uint256[] _outcomes)` (external)



### <span id="SocialBet-cancelEvent-uint256-"></span> `cancelEvent(uint256 _eventId)` (external)



### <span id="SocialBet-openOffer-uint256-uint256-uint256-uint256-uint256-uint256-"></span> `openOffer(uint256 _eventId, uint256 _marketIndex, uint256 _amount, uint256 _price, uint256 _outcome, uint256 _timestampExpiration)` (external)



### <span id="SocialBet-closeOffer-uint256-"></span> `closeOffer(uint256 _offerId)` (external)



### <span id="SocialBet-buyOffer-uint256-uint256-"></span> `buyOffer(uint256 _offerId, uint256 _amount)` (public)



### <span id="SocialBet-buyOfferBulk-uint256---uint256-"></span> `buyOfferBulk(uint256[] _offerIds, uint256 _amount)` (external)



### <span id="SocialBet-claimBetEarnings-uint256-"></span> `claimBetEarnings(uint256 _betId)` (external)



### <span id="SocialBet-getMarket-uint256-uint256-"></span> `getMarket(uint256 _eventId, uint256 _marketIndex) → struct SocialBet.Market` (public)



### <span id="SocialBet-LogNewEvent-uint256-bytes32-uint256---"></span> `LogNewEvent(uint256 id, bytes32 ipfsAddress, uint256[] markets)`



### <span id="SocialBet-LogNewMarkets-uint256-uint256---"></span> `LogNewMarkets(uint256 id, uint256[] markets)`



### <span id="SocialBet-LogResultEvent-uint256-"></span> `LogResultEvent(uint256 id)`



### <span id="SocialBet-LogCancelEvent-uint256-"></span> `LogCancelEvent(uint256 id)`



### <span id="SocialBet-LogNewOffer-uint256-uint256-uint256-address-uint256-uint256-uint256-uint256-"></span> `LogNewOffer(uint256 id, uint256 eventId, uint256 marketIndex, address owner, uint256 amount, uint256 price, uint256 outcome, uint256 timestampExpiration)`



### <span id="SocialBet-LogUpdateOffer-uint256-uint256-uint256-"></span> `LogUpdateOffer(uint256 id, uint256 amount, uint256 price)`



### <span id="SocialBet-LogNewBet-uint256-uint256-uint256-uint256-uint256-uint256-uint256-"></span> `LogNewBet(uint256 id, uint256 eventId, uint256 marketIndex, uint256 backPosition, uint256 layPosition, uint256 amount, uint256 outcome)`



### <span id="SocialBet-LogBetClosed-uint256-"></span> `LogBetClosed(uint256 id)`



### <span id="SocialBet-LogNewPosition-uint256-uint256-address-uint256-"></span> `LogNewPosition(uint256 id, uint256 betId, address owner, uint256 amount)`




// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.10;

import {ICollectNFT} from '../interfaces/ICollectNFT.sol';
import {ILensHub} from '../interfaces/ILensHub.sol';
import {Errors} from '../libraries/Errors.sol';
import {Events} from '../libraries/Events.sol';
import {LensNFTBase} from './base/LensNFTBase.sol';

/**
 * @title PersonaNFT
 * @author Lens Protocol
 *
 * @notice This is the NFT contract that is minted upon collecting a given publication. It is cloned upon
 * the first collect for a given publication, and the token URI points to the original publication's contentURI.
 * 
 * 
 * Based on CollectNFT
 * Design Detachable Heads (Personas)
 *  Preferably, just regular ERC721 NFTs
 * 
 */
contract PersonaNFT is ICollectNFT, LensNFTBase {
    address public immutable HUB;

    uint256 internal _profileId;
    uint256 internal _pubId;
    uint256 internal _tokenIdCounter;

    bool private _initialized;

    // We create the PersonaNFT with the pre-computed HUB address before deploying the hub proxy in order
    // to initialize the hub proxy at construction.
    constructor(address hub) {
        HUB = hub;
    }

    /// @inheritdoc ICollectNFT
    function initialize(
        uint256 profileId,
        uint256 pubId,
        string calldata name,
        string calldata symbol
    ) external override {
        if (_initialized) revert Errors.Initialized();
        _initialized = true;
        _profileId = profileId;
        _pubId = pubId;
        super._initialize(name, symbol);
        // emit Events.CollectNFTInitialized(profileId, pubId, block.timestamp);    //TBD
    }

    /// @inheritdoc ICollectNFT
    function mint(address to) external override {
        if (msg.sender != HUB) revert Errors.NotHub();
        uint256 tokenId = ++_tokenIdCounter;
        _mint(to, tokenId);
    }

    /// @inheritdoc ICollectNFT
    function getSourcePublicationPointer() external view override returns (uint256, uint256) {
        return (_profileId, _pubId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert Errors.TokenDoesNotExist();
        return ILensHub(HUB).getContentURI(_profileId, _pubId);
    }

    /**
     * @dev Upon transfers, we emit the transfer event in the hub.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
        // ILensHub(HUB).emitCollectNFTTransferEvent(_profileId, _pubId, tokenId, from, to);    //TBD
    }
}

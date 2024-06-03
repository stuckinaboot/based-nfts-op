// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 .0;

import "./moons/MoonStructs.sol";
import { ERC1155 } from "@solady/tokens/ERC1155.sol";
import { AllowList } from "./utils/AllowList.sol";
import { EventsConstantsErrors } from "./EventsConstantsErrors.sol";
import { MoonCalculations } from "./moons/MoonCalculations.sol";
import { MoonRenderer } from "./moons/MoonRenderer.sol";
import { Utils } from "./moons/Utils.sol";

/// @title BasedMoon
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
contract BasedMoon is ERC1155, AllowList, EventsConstantsErrors {
  mapping(address user => uint8 minted) internal _allowListMinted;

  uint256 public immutable MINT_CLOSED_TIMESTAMP;

  uint256 internal constant INTERVAL_BETWEEN_ANIMATION_SAMPLES = MoonCalculations.LUNAR_MONTH_LENGTH_IN_MS / 115;

  uint16 internal constant MOON_RADIUS = 32;
  uint16 internal constant VIEW_SIZE = 200;
  uint16 internal constant OFFSET = (VIEW_SIZE - 2 * MOON_RADIUS) / 2;
  uint16 internal constant MOON_HUE = 226;
  uint8 internal constant BORDER_SATURATION = 87;

  uint256 public totalSupply;

  constructor(bytes32 allowListMerkleRoot) AllowList(allowListMerkleRoot) {
    MINT_CLOSED_TIMESTAMP = block.timestamp + 48 hours;
  }

  /// @notice Mint tokens for allowlisted minters
  /// @param proof proof
  /// @param amount amount to mint
  function mintAllowList(bytes32[] calldata proof, uint8 amount) external onlyAllowListed(proof) {
    // Check mint open
    if (block.timestamp > MINT_CLOSED_TIMESTAMP) {
      revert MintClosed();
    }

    // Check not exceeding max allowed
    if (_allowListMinted[msg.sender] + amount > _allowListMintMaxPerWallet) {
      // Check wallet is not exceeding max allowed during allowlist phase
      revert AllowListMintCapPerWalletExceeded();
    }

    // Increase allowlist minted by amount
    unchecked {
      _allowListMinted[msg.sender] += amount;

      // Increase total supply by amount
      totalSupply += amount;
    }

    _mint(msg.sender, 1, amount, "");
  }

  /// @notice Mint tokens
  /// @param amount amount to mint
  function mintPublic(uint8 amount) external payable {
    // Check mint open
    if (block.timestamp > MINT_CLOSED_TIMESTAMP) {
      revert MintClosed();
    }

    // Check payment
    if (amount * PRICE != msg.value) {
      revert InvalidPaymentAmount();
    }

    unchecked {
      // Increase total supply by amount
      totalSupply += amount;
    }

    _mint(msg.sender, 1, amount, "");
  }

  /// @notice Generate onchain moon art (animation and svg)
  /// @param initialTimestamp initial timestamp
  /// @param onlySvg only compute svg
  /// @return art svg, animation html
  function generateOnChainMoon(
    uint256 initialTimestamp,
    bool onlySvg
  ) public pure returns (string memory, string memory) {
    string memory moonHueStr = Utils.uint2str(MOON_HUE);
    MoonImageConfig memory moonConfig = MoonImageConfig({
      moonRadius: MOON_RADIUS,
      xOffset: OFFSET,
      yOffset: OFFSET,
      viewWidth: VIEW_SIZE,
      viewHeight: VIEW_SIZE,
      borderRadius: 3,
      borderWidth: 3,
      borderType: "solid",
      colors: MoonImageColors({
        moon: Utils.hslaString(moonHueStr, 100, 50),
        moonHue: MOON_HUE,
        border: Utils.hslaString(moonHueStr, BORDER_SATURATION, 50),
        borderSaturation: BORDER_SATURATION,
        background: "hsla(0, 0%, 0%)",
        backgroundLightness: 0,
        backgroundGradientColor: Utils.hslaString(moonHueStr, 100, 60)
      })
    });

    string memory moonSvgText;
    string memory firstSvg;

    for (
      uint256 timestamp = initialTimestamp;
      timestamp < initialTimestamp + MoonCalculations.LUNAR_MONTH_LENGTH_IN_MS;
      timestamp += INTERVAL_BETWEEN_ANIMATION_SAMPLES
    ) {
      string memory moonSvg = MoonRenderer.renderWithTimestamp(moonConfig, timestamp);
      if (timestamp == initialTimestamp) {
        firstSvg = moonSvg;
        moonSvgText = string.concat(
          '<!DOCTYPE html><html><head><style type="text/css">html{overflow:hidden}body{margin:0}#moon{display:block;margin:auto}</style></head><body><div id="moonDiv"></div><script>let gs=[`',
          moonSvg,
          "`"
        );
        if (onlySvg) {
          // This allows for returning an SVG with much lower gas usage than used when computing the animation
          return (firstSvg, "");
        }
      } else {
        moonSvgText = string.concat(moonSvgText, ",`", moonSvg, "`");
      }
    }

    return (
      firstSvg,
      string.concat(
        moonSvgText,
        '];let $=document.getElementById.bind(document);$("moonDiv").innerHTML=gs[0];let mo=$("moonDiv");let u=e=>{let t=$("moon").getBoundingClientRect();$("moonDiv").innerHTML=gs[Math.max(0,Math.min(Math.floor(((e-t.left)/t.width)*gs.length),gs.length-1))];};mo.onmousemove=e=>u(e.clientX);mo.addEventListener("touchstart",e=>{let t=e=>u(e.touches[0].clientX);n=()=>{e.target.removeEventListener("touchmove",t),e.target.removeEventListener("touchend",n);};e.target.addEventListener("touchmove",t);e.target.addEventListener("touchend",n);});</script></body></html>'
      )
    );
  }

  /// @notice Get uri for particular token
  /// @param id token id
  /// @return uri for token
  function uri(uint256 id) public view virtual override returns (string memory) {
    if (id != 1) {
      revert TokenUnknown();
    }

    (string memory moonSvg, string memory moonAnimation) = generateOnChainMoon(block.timestamp * 1e3, false);
    return
      Utils.formatTokenURI(
        Utils.svgToImageURI(moonSvg),
        Utils.htmlToURI(moonAnimation),
        "Based Moon",
        "Based Moon is an onchain interactive moon on Base. All moon art is generated onchain and updates in real-time, based on the current block time and using an onchain SVG library, to closely mirror the phase of the moon in the real world.",
        "[]"
      );
  }

  /// @notice Withdraw all ETH from the contract.
  function withdraw() external {
    (bool success, ) = _VAULT_ADDRESS.call{ value: address(this).balance }("");
    require(success);
  }
}

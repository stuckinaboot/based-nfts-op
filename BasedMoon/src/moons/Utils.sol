// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 .0;

import { Base64 } from "@solady/utils/Base64.sol";
import { LibString } from "./LibString.sol";

// Core utils used extensively to format CSS and numbers.
library Utils {
  using LibString for uint256;
  using LibString for uint8;
  using LibString for uint16;

  string internal constant _BASE64_TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  function hslaString(string memory hue, uint8 saturation, uint8 lightness) internal pure returns (string memory) {
    return string.concat("hsla(", hue, ",", saturation.toString(), "%,", lightness.toString(), "%,100%)");
  }

  // converts an unsigned integer to a string
  function uint2str(uint256 _i) internal pure returns (string memory) {
    if (_i == 0) {
      return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      ++len;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }

  function htmlToURI(string memory _source) internal pure returns (string memory) {
    return string.concat("data:text/html;base64,", Base64.encode(bytes(_source)));
  }

  function svgToImageURI(string memory _source) internal pure returns (string memory) {
    return string.concat("data:image/svg+xml;base64,", Base64.encode(bytes(_source)));
  }

  function formatTokenURI(
    string memory _imageURI,
    string memory _animationURI,
    string memory _name,
    string memory _description,
    string memory _properties
  ) internal pure returns (string memory) {
    return
      string.concat(
        "data:application/json;base64,",
        Base64.encode(
          bytes(
            bytes(
              string.concat(
                '{"name":"',
                _name,
                '","description":"',
                _description,
                '","attributes":',
                _properties,
                ',"image":"',
                _imageURI,
                '","animation_url":"',
                _animationURI,
                '"}'
              )
            )
          )
        )
      );
  }
}

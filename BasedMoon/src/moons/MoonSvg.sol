// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 .0;

import "./SVG.sol";
import { MoonImageConfig } from "./MoonStructs.sol";

/// @title MoonSvg
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
library MoonSvg {
    struct SvgContainerParams {
        uint16 x;
        uint16 y;
        uint16 width;
        uint16 height;
    }

    struct EllipseParams {
        uint16 cx;
        uint16 cy;
        uint256 rx;
        uint16 ry;
        string color;
        bool forceUseBackgroundColor;
    }

    function getBackgroundRadialGradientDefinition(
        // RectParams memory rectParams,
        MoonImageConfig memory moonConfig,
        uint256 moonVerticalRadius
    )
        internal
        pure
        returns (string memory)
    {
        return svg.radialGradient(
            string.concat(
                svg.prop("id", "brG"),
                // Set radius to 75% to smooth out the radial gradient against
                // the background and moon color
                svg.prop("r", "75%")
            ),
            string.concat(
                svg.stop(
                    string.concat(
                        svg.prop(
                            "offset",
                            string.concat(
                                Utils.uint2str(
                                    // Ensure that the gradient has the rect color up to at least the moon radius
                                    // Note: the reason we do moon radius * 100 * 3 / 2 is because
                                    // we multiply by 100 to get a percent, then multiply by 3 and divide by 2
                                    // to get ~1.5 * moon radius, which is sufficiently large given the background
                                    // radial
                                    // gradient radius is being scaled by 75% (50% would be normal size, 75% is scaled
                                    // up),
                                    // which smooths out the gradient and reduces the presence of a color band
                                    (((moonVerticalRadius * 100) * 3) / 2) / moonConfig.viewHeight
                                ),
                                "%"
                            )
                        ),
                        svg.prop("stop-color", moonConfig.colors.background)
                    )
                ),
                svg.stop(
                    string.concat(
                        svg.prop("offset", "100%"), svg.prop("stop-color", moonConfig.colors.backgroundGradientColor)
                    )
                )
            )
        );
    }

    function getMoonFilterDefinition(uint16 moonRadiusY) internal pure returns (string memory) {
        uint16 position = moonRadiusY * 2;
        return svg.filter(
            string.concat(svg.prop("id", "mF")),
            string.concat(
                svg.feSpecularLighting(
                    string.concat(
                        svg.prop("result", "out"),
                        svg.prop("specularExponent", "20"),
                        svg.prop("lighting-color", "#bbbbbb")
                    ),
                    svg.fePointLight(
                        string.concat(svg.prop("x", position), svg.prop("y", position), svg.prop("z", position))
                    )
                ),
                svg.feComposite(
                    string.concat(
                        svg.prop("in", "SourceGraphic"),
                        svg.prop("in2", "out"),
                        svg.prop("operator", "arithmetic"),
                        svg.prop("k1", "0"),
                        svg.prop("k2", "1"),
                        svg.prop("k3", "1"),
                        svg.prop("k4", "0")
                    )
                )
            )
        );
    }

    function getMoonFilterMask(
        SvgContainerParams memory svg1,
        SvgContainerParams memory svg2,
        EllipseParams memory ellipse1,
        EllipseParams memory ellipse2,
        // RectParams memory rect
        MoonImageConfig memory moonConfig
    )
        internal
        pure
        returns (string memory)
    {
        return svg.mask(
            svg.prop("id", "mfM"),
            string.concat(
                svg.rect(
                    string.concat(
                        svg.prop("width", moonConfig.viewWidth),
                        svg.prop("height", moonConfig.viewHeight),
                        svg.prop("fill", "#000")
                    )
                ),
                getEllipseElt(
                    svg1,
                    ellipse1,
                    // Black rect for masking purposes; where this rect is visible will be hidden
                    "#000",
                    // White ellipse for masking purposes; where this ellipse is visible will be shown
                    "#FFF"
                ),
                getEllipseElt(
                    svg2,
                    ellipse2,
                    // Black rect for masking purposes; where this rect is visible will be hidden
                    "#000",
                    // White ellipse for masking purposes; where this ellipse is visible will be shown
                    "#FFF"
                )
            )
        );
    }

    function getEllipseElt(
        SvgContainerParams memory svgContainer,
        EllipseParams memory ellipse,
        string memory rectBackgroundColor,
        string memory ellipseColor
    )
        internal
        pure
        returns (string memory)
    {
        return svg.svgTag(
            string.concat(
                svg.prop("x", svgContainer.x),
                svg.prop("y", svgContainer.y),
                svg.prop("height", svgContainer.height),
                svg.prop("width", svgContainer.width)
            ),
            svg.ellipse(
                string.concat(
                    svg.prop("cx", ellipse.cx),
                    svg.prop("cy", ellipse.cy),
                    svg.prop("rx", ellipse.rx),
                    svg.prop("ry", ellipse.ry),
                    svg.prop("fill", ellipse.forceUseBackgroundColor ? rectBackgroundColor : ellipseColor)
                )
            )
        );
    }

    function getBorderStyleProp(MoonImageConfig memory moonConfig) internal pure returns (string memory) {
        return svg.prop(
            "style",
            string.concat(
                "outline:",
                Utils.uint2str(moonConfig.borderWidth),
                "px ",
                moonConfig.borderType,
                " ",
                moonConfig.colors.border,
                ";outline-offset:-",
                Utils.uint2str(moonConfig.borderWidth),
                "px;border-radius:",
                Utils.uint2str(moonConfig.borderRadius),
                "%"
            )
        );
    }

    function getMoonBackgroundMaskDefinition(
        // RectParams memory rect,
        MoonImageConfig memory moonConfig,
        uint256 moonRadius
    )
        internal
        pure
        returns (string memory)
    {
        return svg.mask(
            svg.prop("id", "mbM"),
            string.concat(
                svg.rect(
                    string.concat(
                        svg.prop("width", moonConfig.viewWidth),
                        svg.prop("height", moonConfig.viewHeight),
                        // Everything under a white pixel will be visible
                        svg.prop("fill", "#FFF")
                    )
                ),
                svg.circle(
                    string.concat(
                        svg.prop("cx", moonConfig.viewWidth / 2),
                        svg.prop("cy", moonConfig.viewHeight / 2),
                        // Add 1 to moon radius as slight buffer.
                        svg.prop("r", moonRadius + 1)
                    )
                )
            )
        );
    }

    function getDefinitions(
        MoonImageConfig memory moonConfig,
        // RectParams memory rect,
        SvgContainerParams memory svg1,
        SvgContainerParams memory svg2,
        EllipseParams memory ellipse1,
        EllipseParams memory ellipse2,
        string memory alienArtMoonFilterDefinition
    )
        internal
        pure
        returns (string memory)
    {
        return svg.defs(
            string.concat(
                getBackgroundRadialGradientDefinition(moonConfig, ellipse1.ry),
                bytes(alienArtMoonFilterDefinition).length > 0
                    ? alienArtMoonFilterDefinition
                    : getMoonFilterDefinition(ellipse1.ry),
                getMoonBackgroundMaskDefinition(moonConfig, ellipse1.ry),
                getMoonFilterMask(svg1, svg2, ellipse1, ellipse2, moonConfig)
            )
        );
    }

    function getMoonSvgProps(uint16 borderRadius) internal pure returns (string memory) {
        return string.concat(
            svg.prop("xmlns", "http://www.w3.org/2000/svg"),
            // Include id so that the moon element can be accessed by JS
            svg.prop("id", "moon"),
            svg.prop("height", "100%"),
            svg.prop("viewBox", "0 0 200 200"),
            svg.prop("style", string.concat("border-radius:", Utils.uint2str(borderRadius), "%;max-height:100vh"))
        );
    }

    function generateMoon(
        MoonImageConfig memory moonConfig,
        SvgContainerParams memory svg1,
        SvgContainerParams memory svg2,
        EllipseParams memory ellipse1,
        EllipseParams memory ellipse2,
        string memory alienArt,
        string memory alienArtMoonFilterDefinition
    )
        internal
        pure
        returns (string memory)
    {
        string memory ellipseElt = string.concat(
            getEllipseElt(svg1, ellipse1, moonConfig.colors.background, ellipse1.color),
            getEllipseElt(svg2, ellipse2, moonConfig.colors.background, ellipse2.color)
        );

        string memory rect;

        {
            // 1000 or more signals don't include rect
            if (moonConfig.borderWidth < 1000) {
                string memory rectProps1 = string.concat(
                    svg.prop(
                        "fill",
                        bytes(moonConfig.colors.backgroundGradientColor).length > 0
                            ? "url(#brG)"
                            : moonConfig.colors.background
                    ),
                    svg.prop("width", moonConfig.viewWidth),
                    svg.prop("height", moonConfig.viewHeight)
                );
                string memory rectProps2 = string.concat(
                    svg.prop("rx", string.concat(Utils.uint2str(moonConfig.borderRadius), "%")),
                    svg.prop("ry", string.concat(Utils.uint2str(moonConfig.borderRadius), "%"))
                );
                rect = svg.rect(string.concat(rectProps1, rectProps2, getBorderStyleProp(moonConfig)));
            }
        }

        string memory definitions =
            getDefinitions(moonConfig, svg1, svg2, ellipse1, ellipse2, alienArtMoonFilterDefinition);

        // borderWidth at 2000 signals no alien art
        string memory alienArtFull = moonConfig.borderWidth < 2000
            ? svg.g(
                // Apply mask to block out the moon area from alien art,
                // which is necessary in order for the moon to be clearly visible when displayed
                svg.prop("mask", "url(#mbM)"),
                alienArt
            )
            : "";

        return svg.svgTag(
            getMoonSvgProps(moonConfig.borderRadius),
            string.concat(
                definitions,
                svg.svgTag(
                    svg.NULL,
                    string.concat(
                        rect,
                        // Intentionally put alien art behind the moon in svg ordering
                        alienArtFull,
                        svg.g(
                            string.concat(
                                // Apply filter to moon
                                svg.prop("filter", "url(#mF)"),
                                // Apply mask to ensure filter only applies to the visible portion of the moon
                                svg.prop("mask", "url(#mfM)")
                            ),
                            ellipseElt
                        )
                    )
                )
            )
        );
    }
}

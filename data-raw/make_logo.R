# Package logo (man/figures/logo.png).
#
# The current logo is a designer hex sticker — three cubes connected by branch
# arrows over a dark purple background — supplied as `logo_source.svg` in this
# directory. The PNG shipped at `man/figures/logo.png` was rendered from the
# 600 dpi source at 1200x1385 px. To re-render from the SVG (requires the
# {rsvg} package):
#
#   rsvg::rsvg_png("data-raw/logo_source.svg",
#                  file = "man/figures/logo.png",
#                  width = 1200L)
#
# After updating the logo, regenerate the pkgdown favicons:
#
#   pkgdown::build_favicons(overwrite = TRUE)
#
# Note: a previous version of this script generated a programmatic logo via
# ggplot2; that has been retired in favour of the designer SVG. The history
# of that version is preserved in git.

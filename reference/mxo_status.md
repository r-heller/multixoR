# Game status

Game status

## Usage

``` r
mxo_status(game)
```

## Arguments

- game:

  An `mxo_game` object.

## Value

A list with components:

- `status` (chr): one of `"in_progress"`, `"x_win"`, `"o_win"`,
  `"draw"`.

- `winner` (int): `NA_integer_`, `1L` (X), or `2L` (O).

- `win_line` (list or NULL): the winning cells if terminal-with-win.

## Examples

``` r
mxo_status(mxo_new_game())
#> $status
#> [1] "in_progress"
#> 
#> $winner
#> [1] NA
#> 
#> $win_line
#> NULL
#> 
```

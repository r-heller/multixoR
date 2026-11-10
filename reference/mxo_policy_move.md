# Apply a policy to choose a move

Apply a policy to choose a move

## Usage

``` r
mxo_policy_move(policy, game)
```

## Arguments

- policy:

  An `mxo_policy` object.

- game:

  An `mxo_game` object.

## Value

A one-row legal-moves tibble (or zero-row at terminal states).

## Examples

``` r
set.seed(1)
mxo_policy_move(mxo_policy("random"), mxo_new_game(n = 3L))
#> # A tibble: 1 × 5
#>   kind    L_src t_src   idx player
#>   <chr>   <int> <int> <int>  <int>
#> 1 present     0     0    24      1
```

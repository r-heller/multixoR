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

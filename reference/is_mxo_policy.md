# Test whether an object is a multixoR policy

Test whether an object is a multixoR policy

## Usage

``` r
is_mxo_policy(x)
```

## Arguments

- x:

  An object.

## Value

Logical scalar.

## Examples

``` r
is_mxo_policy(mxo_policy("random"))
#> [1] TRUE
is_mxo_policy(list())
#> [1] FALSE
```

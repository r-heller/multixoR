# Auto-render a multixoR game

Dispatches to the renderer named by `type`.

## Usage

``` r
# S3 method for class 'mxo_game'
autoplot(object, type = c("multiverse", "board", "threats", "tree"), ...)
```

## Arguments

- object:

  An `mxo_game` object.

- type:

  One of `"multiverse"` (default), `"board"`, `"threats"`, `"tree"`.

- ...:

  Additional arguments forwarded to the selected renderer. For
  `type = "board"`, supply `L` and `t`.

## Value

A `ggplot` (or `plotly` for `type = "board", view = "cube"`).

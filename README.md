# GraphQL in OCaml Tutorial

This repo contains the slides, code and exercises for the GraphQL in OCaml tutorial at [CUFP 2017](http://cufp.org/2017/c8-andreas-graphql-servers-in-ocaml.html).

You can find the slides in the [`gh-pages`-branch](https://github.com/andreas/ocaml-graphql-tutorial/tree/gh-pages) or [browse them online](https://andreas.github.io/ocaml-graphql-tutorial).

### Building and running the code

The code has been tested with OCaml 4.04.2 and the following versions of OPAM packages:

- `graphql-lwt` 0.3.0
- `ppx_graphql` 0.1.0
- `jbuilder` 1.0+beta11
- `cohttp-lwt-unix` 0.99.0
- `tls` 0.8.0
- `opam-lib` 1.3.1

You can achieve this with the following two commands:

```
opam switch 4.04.2
opam install graphql-lwt.0.3.0 ppx_graphql.0.1.0 jbuilder.1.0+beta11 cohttp-lwt-unix.0.99.0 tls.0.8.0 opam-lib.1.3.1
```

Running the Github CLI (exercise 3):

```
GITHUB_TOKEN=abc jbuilder build @github_cli
```

Running the GraphQL server (exercise 4 - 7):

```
GITHUB_TOKEN=abc jbuilder build @server --no-buffer
```

(`GITHUB_TOKEN` is only required from exercise 6 and onwards)

Now visit http://localhost:8080/graphql.

### Documentation

- [`Graphql_lwt.Schema` documentation](https://andreas.github.io/ocaml-graphql-server/graphql-lwt/Graphql_lwt/Schema/index.html)
- [`andreas/ocaml-graphql-server`](https://github.com/andreas/ocaml-graphql-server)
- [`andreas/ppx_graphql`](https://github.com/andreas/ppx_graphql)


#### Lwt Cheatsheet

```ocaml
module type Lwt = sig
  module Infix = sig
    val (>>=) : 'a t -> ('a -> 'b t) -> 'b t
    val (>|=) : 'a t -> ('a -> 'b) -> 'b t
  end
end

module type Lwt_result = sig
  module Infix = sig
    val (>>=) : ('a, 'c) result Lwt.t ->
                ('a -> ('b, 'c) result Lwt.t) ->
                ('b, 'c) result Lwt.t

    val (>|=) : ('a, 'c) result Lwt.t ->
                ('a -> 'b) ->
                ('b, 'c) result Lwt.t
  end
end

(* Lwt.Infix example *)
let _ : string Lwt.t =
  let open Lwt.Infix in
  Lwt_io.(read_line_opt stdin) >|= function
  | None -> "No line read"
  | Some line -> "Line from stdin: %s" line

(* Lwt_result.Infix example *)
let _ : int result Lwt.t =
  let open Lwt_result.Infix in
  Lwt.return (Ok 41) >|= fun n ->
  n + 1
```

### Exercise Solutions

You can find solutions to the exercises as git tags of this repo:

- [Exercise 3 solutions](https://github.com/andreas/ocaml-graphql-tutorial/tree/exercise-3)
- [Exercise 4 solutions](https://github.com/andreas/ocaml-graphql-tutorial/tree/exercise-4)
- [Exercise 5 solutions](https://github.com/andreas/ocaml-graphql-tutorial/tree/exercise-5)
- [Exercise 6 solutions](https://github.com/andreas/ocaml-graphql-tutorial/tree/exercise-6)
- [Exercise 7 solutions](https://github.com/andreas/ocaml-graphql-tutorial/tree/exercise-7)

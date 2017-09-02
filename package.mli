type relop = [`Eq | `Neq | `Geq | `Gt | `Leq | `Lt]
type version_constraint = relop * string

type t = {
  name        : string;
  version     : string;
  maintainer  : string list;
  homepage    : string list;
  authors     : string list;
  license     : string list;
  doc         : string list;
  tags        : string list;
  bug_reports : string list;
  dependencies : (string * version_constraint option) list;
  git_repo    : string option;
}

val github_owner_and_name : t -> (string * string) option
val find_by_name : t list -> string -> t option
val load_all : unit -> t list

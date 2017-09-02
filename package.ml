type relop = [`Eq | `Neq | `Geq | `Gt | `Leq | `Lt]
type version_constraint = relop * string

type t = {
  name         : string;
  version      : string;
  maintainer   : string list;
  homepage     : string list;
  authors      : string list;
  license      : string list;
  doc          : string list;
  tags         : string list;
  bug_reports  : string list;
  dependencies : (string * version_constraint option) list;
  git_repo     : string option;
}

let git_repo_of_dev_repo = function
  | Some (OpamTypes.Git (url, _)) -> Some url
  | _ -> None

let versions pkg_idx =
  OpamPackage.Map.fold (fun nv _ map ->
    let name = OpamPackage.name nv in
    let versions, map =
      try
        let versions = OpamPackage.Name.Map.find name map in
        let map = OpamPackage.Name.Map.remove name map in
        versions, map
      with Not_found ->
        OpamPackage.Version.Set.empty, map in
    let versions = OpamPackage.Version.Set.add
      (OpamPackage.version nv) versions in
    OpamPackage.Name.Map.add name versions map
  ) pkg_idx OpamPackage.Name.Map.empty

let max_versions versions =
  OpamPackage.Name.Map.map (fun versions ->
    OpamPackage.Version.Set.max_elt versions
  ) versions

let max_packages max_versions =
  OpamPackage.Name.Map.fold (fun name version set ->
    OpamPackage.Set.add (OpamPackage.create name version) set
  ) max_versions OpamPackage.Set.empty

let simplify_version_constraint = function
  | OpamFormula.Atom (relop, version) ->
      Some (relop, OpamPackage.Version.to_string version)
  | _ ->
      None

let simplify_depends formula =
  formula
  |> OpamFormula.ands_to_list
  |> List.fold_left (fun memo -> function
      | OpamFormula.Atom (name, ([], version_constraint)) ->
          let name' = OpamPackage.Name.to_string name in
          let version_constraint' = simplify_version_constraint version_constraint in
          (name', version_constraint')::memo
      | _ ->
          memo
     ) []

let load_all () =
  if not (OpamStateConfig.load_defaults @@ OpamStateConfig.opamroot ()) then
    failwith "Failed to load default OPAM config";
  let state = OpamState.load_state "foo" OpamStateConfig.(!r.current_switch) in
  let versions = versions state.opams in
  let max_versions = max_versions versions in
  let max_packages = max_packages max_versions in
  let opams = OpamPackage.Set.fold (fun pkg memo -> (OpamState.opam state pkg)::memo) max_packages [] in
  List.map (fun opam ->
    let open OpamFile.OPAM in
    {
      name = name opam |> OpamPackage.Name.to_string;
      version = version opam |> OpamPackage.Version.to_string;
      maintainer = maintainer opam;
      homepage = homepage opam;
      authors = author opam;
      license = license opam;
      doc = doc opam;
      tags = tags opam;
      bug_reports = bug_reports opam;
      dependencies = depends opam |> simplify_depends;
      git_repo = dev_repo opam |> git_repo_of_dev_repo;
    }
  ) opams

let github_owner_and_name t =
  match t.git_repo with
  | None -> None
  | Some url ->
    let regexp = Str.regexp "github.com/\\(.*\\)/\\(.*\\)\\.git" in
    try
      ignore(Str.search_forward regexp url 0);
      Some Str.(matched_group 1 url, matched_group 2 url)
    with Not_found ->
      None

let find_by_name ts name =
  try
    Some (List.find (fun pkg -> pkg.name = name) ts)
  with Not_found ->
    None

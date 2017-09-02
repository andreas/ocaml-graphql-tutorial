open Lwt.Infix

let print_repo_information () =
  let token = Unix.getenv "GITHUB_TOKEN" in
  Github.find_repo ~token ~owner:"andreas" ~name:"ocaml-graphql-server" () >|= function
  | Ok rsp ->
      begin match rsp#repository with
      | Some repo ->
          Format.printf "Stars: %d" repo#stargazers#totalCount
      | None ->
          Format.printf "Repo not found"
      end
  | Error (`JSON err) ->
      Format.printf "JSON error! %s" err
  | Error (`HTTP (rsp, body)) ->
      Format.printf "HTTP error! %s" body

let () =
  print_repo_information ()
  |> Lwt_main.run

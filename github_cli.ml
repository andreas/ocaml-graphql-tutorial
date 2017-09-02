open Lwt.Infix

let print_repo_information () =
  let token = Unix.getenv "GITHUB_TOKEN" in
  (* Complete me! *)

let () =
  print_repo_information ()
  |> Lwt_main.run

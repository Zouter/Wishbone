#' Execute Wishbone
#'
#' @param counts Counts
#' @param start_cell_id ID of start cell
#' @param knn k nearest neighbours for diffusion
#' @param n_diffusion_components number of diffusion components
#' @param n_pca_components number of pca components
#' @param markers markers to use
#' @param branch whether or not to branch or linear
#' @param k k param
#' @param num_waypoints number of waypoints
#' @param normalize whether or not to normalize
#' @param epsilon epsilon param
#' @param verbose whether or not to print the wishbone output
#'
#' @importFrom jsonlite toJSON read_json
#' @importFrom glue glue
#' @importFrom tibble tibble
#' @importFrom purrr %>%
#' @importFrom readr read_csv
#' @importFrom dplyr rename rename_if
#' @importFrom utils write.table
#'
#' @export
Wishbone <- function(
  counts,
  start_cell_id,
  knn = 10,
  n_diffusion_components = 2,
  n_pca_components = 15,
  markers = "~",
  branch = TRUE,
  k = 15,
  num_waypoints = 50,
  normalize = TRUE,
  epsilon = 1,
  verbose = F
) {
  # create temporary folder
  temp_folder <- tempfile()
  dir.create(temp_folder, recursive = TRUE)

  # write counts to temporary folder
  expr <- log2(counts+1)
  utils::write.table(as.data.frame(counts), paste0(temp_folder, "/counts.tsv"), sep="\t")

  # write parameters to temporary folder
  params <- as.list(environment())[formalArgs(Wishbone)]
  params <- params[names(params) != "counts"]
  params[["components_list"]] <- seq_len(n_diffusion_components)-1

  write(
    jsonlite::toJSON(params, auto_unbox = TRUE),
    paste0(temp_folder, "/params.json")
  )

  # execute python script
  output <- system2(
    "/bin/bash",
    args = c(
      "-c",
      shQuote(glue::glue(
        "cd {find.package('Wishbone')}/venv",
        "source bin/activate",
        "python {find.package('Wishbone')}/wrapper.py {temp_folder}",
        .sep = ";"))
    ), stdout = TRUE, stderr = TRUE
  )

  if (verbose) cat(output, "\n", sep="")

  # read output
  branch_filename <- paste0(temp_folder, "/branch.json")
  trajectory_filename <- paste0(temp_folder, "/trajectory.json")
  dimred_filename <- paste0(temp_folder, "/dm.csv")

  branch_assignment <- jsonlite::read_json(branch_filename) %>%
    unlist() %>%
    {tibble::tibble(branch = ., cell_id = names(.))}

  trajectory <- jsonlite::read_json(trajectory_filename) %>%
    unlist() %>%
    {tibble::tibble(time = ., cell_id = names(.))}

  space <- readr::read_csv(dimred_filename) %>%
    rename(cell_id = X1) %>%
    rename_if(is.numeric, funs(paste0("Comp", .)))

  # remove temporary output
  unlink(temp_folder, recursive = TRUE)

  list(
    branch_assignment = branch_assignment,
    trajectory = trajectory,
    space = space
  )
}

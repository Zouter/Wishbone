#' @importFrom glue glue
.onLoad <- function(libname, pkgname) {
  if(!dir.exists(glue::glue("bash {find.package('Wishbone')}/venv"))) {
    reinstall()
  }
}

#' Reinstall Wishbone
#'
#' @export
#' @importFrom glue glue
reinstall <- function() {
  system(glue::glue("bash {find.package('Wishbone')}/make {find.package('Wishbone')}/venv"))
}

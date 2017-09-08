.onLoad <- function(libname, pkgname) {
  if(!dir.exists(glue::glue("bash {find.package('Wishbone')}/venv"))) {
    reinstall()
  }
}

#' @export
reinstall <- function() {
  system(glue::glue("bash {find.package('Wishbone')}/make {find.package('Wishbone')}/venv"))
}

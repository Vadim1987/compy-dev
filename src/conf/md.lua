local syntax_i = {
  default     = 0,
  emph        = 7,
  strong      = 2,
  heading     = 5,
  link        = 6,
  list_marker = 10,
  inline      = 4,
}

return {
  default     = Color.black,
  emph        = Color.yellow,
  strong      = Color.red,
  heading     = Color.cyan,
  link        = Color.green,
  list_marker = Color.red + Color.bright,
  inline      = Color.blue + Color.bright,
}

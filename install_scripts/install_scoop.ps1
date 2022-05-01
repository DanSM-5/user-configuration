
Set-ExecutionPolicy RemoteSigned -scope CurrentUser

# install scoop and add "extras" bucket
iwr -useb get.scoop.sh | iex
scoop bucket add extras

# call script to install dependencies
# if (Test-Path ".\app_list_scoop") {
#   . .\app_list_scoop
# }


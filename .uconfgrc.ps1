
############################################
#          GENERAL CONFIGURATIONS          #
############################################

# Follow structure conf folders and files
$user_conf_path = "$HOME\.usr_conf\.uconfrc.ps1"
$user_scripts_path = "C:/user-scripts"
$prj = "$HOME/prj"

# Set Emacs keybindings for readline
# Set-PSReadLineOption -EditMode Emacs

# Set Prediction
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -Colors @{ InlinePrediction = "#B3E5FF" }


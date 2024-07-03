# ONLY FOR PG INSTALLED WITH HOMEBREW
# $1 IS THE PG NAME e.g.: postgresql@16

brew services stop $1

rm -f "/opt/homebrew/var/$1/postmaster.pid"

brew services start $1

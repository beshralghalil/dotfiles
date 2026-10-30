#!/bin/sh
# Start a session (its command = the arguments) through the user's login shell, like SDDM:
# the shell reads its profile (e.g. ~/.zshenv / ~/.zprofile, PATH with ~/.local/bin).
# Called by the sumi greeter. greetd joins the session command with spaces and runs it
# with `sh -c`, so the command must not need quoting: that is why this is a script.
shell=$(getent passwd "$(id -un)" | cut -d: -f7)
case "$shell" in
    */fish) exec "$shell" -l -c 'exec $argv' "$@" ;;
    */*sh)  exec "$shell" -l -c 'exec "$@"' session "$@" ;;
    *)      exec "$@" ;;
esac
